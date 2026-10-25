#!/usr/bin/env node
// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Netresearch DTT GmbH
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const DOCUMENTARY_KEYS = new Set(["_doc", "_provenance"]);
const isText = (value) => typeof value === "string" && value.trim().length > 0;
const isRecord = (value) => value !== null && typeof value === "object" && !Array.isArray(value);

function isReviewDate(value) {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const date = new Date(`${value}T00:00:00Z`);
  return !Number.isNaN(date.getTime()) && date.toISOString().slice(0, 10) === value;
}

function isSourceUrl(value, repo) {
  try {
    const url = new URL(value);
    return url.origin === "https://github.com" && isText(repo)
      && (url.pathname === `/${repo}` || url.pathname.startsWith(`/${repo}/`));
  } catch { return false; }
}

function visibleReadmeLines(readme) {
  let fence = null;
  let inComment = false;
  const lines = typeof readme === "string" ? readme.split(/\r?\n/) : [];
  return lines.map((rawLine) => {
    const marker = rawLine.match(/^\s*(`{3,}|~{3,})(.*)$/);
    if (fence) {
      if (marker && marker[1][0] === fence[0] && marker[1].length >= fence.length && !marker[2].trim()) fence = null;
      return "";
    }
    if (!inComment && marker) { fence = marker[1]; return ""; }
    let visible = "";
    let position = 0;
    while (position < rawLine.length) {
      const boundary = rawLine.indexOf(inComment ? "-->" : "<!--", position);
      if (boundary === -1) {
        if (!inComment) visible += rawLine.slice(position);
        break;
      }
      if (!inComment) visible += rawLine.slice(position, boundary);
      position = boundary + (inComment ? 3 : 4);
      inComment = !inComment;
    }
    const visibleFence = visible.match(/^\s*(`{3,}|~{3,})/);
    if (visibleFence) { fence = visibleFence[1]; return ""; }
    // One result per original line keeps actionable README diagnostics stable.
    return visible;
  });
}

function readmeCatalog(readme) {
  const rows = [];
  let sections = 0;
  let inCatalog = false;
  let inTable = false;
  const lines = visibleReadmeLines(readme);
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const heading = line.match(/^##\s+(.+?)\s*#*\s*$/);
    if (heading) {
      inCatalog = heading[1].toLowerCase() === "available skills";
      if (inCatalog) sections++;
      inTable = false;
    }
    if (!inCatalog) continue;
    if (/^\s*\|\s*Skill\s*\|\s*Repository\s*\|\s*Description\s*\|\s*$/i.test(line)
      && /^\s*\|(?:\s*:?-{3,}:?\s*\|){3}\s*$/.test(lines[i + 1] || "")) {
      inTable = true;
      i++;
      continue;
    }
    const row = inTable && line.match(/^\s*\|\s*([^|]+?)\s*\|/);
    if (row) rows.push({ slug: row[1].replace(/^`([^`]+)`$/, "$1"), line: i + 1 });
    else inTable = false;
  }
  return { rows, sections };
}

/** Pure source-level completeness check. Rendering fallbacks must not hide gaps. */
export function checkCatalogMetadata({ marketplace, displayNames, descriptionsDe, detailsDe, groups, readme }) {
  const issues = [];
  const issue = (code, path, message, slug) => issues.push({ code, path, message, ...(slug ? { slug } : {}) });
  if (!Array.isArray(marketplace?.plugins) || !marketplace.plugins.length) {
    issue("catalog", "marketplace.plugins", "Expected a nonempty canonical catalog.");
    return issues;
  }
  const catalog = new Map();
  for (const plugin of marketplace.plugins) {
    if (!isText(plugin?.name) || catalog.has(plugin.name)) {
      issue("catalog", "marketplace.plugins", "Catalog identifiers must be nonempty and unique.", plugin?.name);
    } else catalog.set(plugin.name, plugin);
  }

  for (const [name, rows] of [["displayNames", displayNames], ["descriptions_de", descriptionsDe], ["details_de", detailsDe]]) {
    if (!isRecord(rows)) {
      issue("metadata-shape", name, "Expected a per-entry metadata object.");
      continue;
    }
    for (const slug of Object.keys(rows)) {
      if (!DOCUMENTARY_KEYS.has(slug) && !catalog.has(slug)) issue("unknown-metadata-entry", `${name}.${slug}`, "Entry is absent from the canonical catalog.", slug);
    }
    for (const slug of catalog.keys()) {
      const row = rows[slug];
      if (!Object.hasOwn(rows, slug) || (name === "details_de" ? !isRecord(row) : !isText(row))) {
        issue("missing-metadata", `${name}.${slug}`, "A curated source row is required; rendering fallbacks do not count.", slug);
        continue;
      }
      if (name !== "details_de") continue;
      for (const field of ["useCases", "expectedOutputs", "contextRequirements"]) {
        if (!Array.isArray(row[field]) || !row[field].length || !row[field].every(isText)) issue("detail-section", `${name}.${slug}.${field}`, "Expected a nonempty array of German presentation strings.", slug);
      }
      const provenance = row.provenance;
      for (const [field, valid] of [
        ["sourceUrl", isSourceUrl(provenance?.sourceUrl, catalog.get(slug).source?.repo)],
        ["reviewedAt", isReviewDate(provenance?.reviewedAt)],
        ["sourceSnapshotSha256", typeof provenance?.sourceSnapshotSha256 === "string" && /^[a-f\d]{64}$/i.test(provenance.sourceSnapshotSha256)],
      ]) {
        if (!valid) issue("detail-provenance", `${name}.${slug}.provenance.${field}`, "Expected a valid source URL, review date and SHA-256 snapshot identifier.", slug);
      }
      // The snapshot records what was reviewed. It is deliberately not compared
      // to the latest fetched README: unrelated releases must not break builds.
    }
  }

  const memberships = new Map([...catalog.keys()].map((slug) => [slug, 0]));
  const presentationGroups = isRecord(groups?.groups) ? groups.groups : {};
  const order = Array.isArray(groups?.order) ? groups.order : [];
  if (!Object.keys(presentationGroups).length || order.some((key) => !Object.hasOwn(presentationGroups, key))
    || Object.keys(presentationGroups).some((key) => order.filter((item) => item === key).length !== 1)) {
    issue("group-order", "groups.order", "Every presentation group must occur exactly once in the rendered order.");
  }
  for (const [key, group] of Object.entries(presentationGroups)) {
    if (!Array.isArray(group.slugs)) {
      issue("group-shape", `groups.groups.${key}.slugs`, "Expected an array of catalog identifiers.");
      continue;
    }
    for (const slug of group.slugs) {
      if (!catalog.has(slug)) issue("unknown-group-entry", `groups.groups.${key}.slugs`, "Group contains an entry absent from the canonical catalog.", slug);
      else memberships.set(slug, memberships.get(slug) + 1);
    }
  }
  for (const [slug, count] of memberships) {
    if (count !== 1) issue("group-membership", "groups.groups", `Expected exactly one presentation group; found ${count}.`, slug);
  }

  const readmeEntries = readmeCatalog(readme);
  if (readmeEntries.sections !== 1) issue("readme-section", "README.md", "Expected exactly one Available Skills section.");
  const readmeCounts = new Map([...catalog.keys()].map((slug) => [slug, 0]));
  for (const { slug, line } of readmeEntries.rows) {
    if (!catalog.has(slug)) issue("unknown-readme-entry", `README.md:${line}`, "Table entry is absent from the canonical catalog.", slug);
    else readmeCounts.set(slug, readmeCounts.get(slug) + 1);
  }
  for (const [slug, count] of readmeCounts) {
    if (count !== 1) issue("readme-membership", "README.md", `Expected one Available Skills table row; found ${count}.`, slug);
  }

  return issues;
}

async function main() {
  const siteRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
  const json = (path) => JSON.parse(readFileSync(resolve(siteRoot, path), "utf8"));
  const marketplace = json("../.claude-plugin/marketplace.json");
  const { default: groups } = await import("../src/_data/groups.js");
  const issues = checkCatalogMetadata({
    marketplace,
    displayNames: json("src/_data/displayNames.json"),
    descriptionsDe: json("src/_data/descriptions_de.json"),
    detailsDe: json("src/_data/details_de.json"),
    groups,
    readme: readFileSync(resolve(siteRoot, "../README.md"), "utf8"),
  });
  console.log(`Catalog metadata check: ${marketplace.plugins.length} entries, ${issues.length} issue(s)`);
  for (const { path, message, slug } of issues) console.error(`  ${path}${slug ? ` [${slug}]` : ""}: ${message}`);
  if (issues.length) process.exitCode = 1;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((error) => { console.error(`Catalog metadata check failed: ${error.message}`); process.exitCode = 1; });
}
