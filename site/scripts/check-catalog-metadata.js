#!/usr/bin/env node
// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Netresearch DTT GmbH
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const DOCUMENTARY_KEYS = new Set(["_doc", "_provenance"]);
const isText = (value) => typeof value === "string" && value.trim().length > 0;
const isRecord = (value) => value !== null && typeof value === "object" && !Array.isArray(value);
const isTextList = (value) => Array.isArray(value) && value.length > 0 && value.every(isText);

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

function fenceToken(line) {
  const value = line.trimStart();
  if (!value.startsWith("```") && !value.startsWith("~~~")) return null;
  let end = 3;
  while (value[end] === value[0]) end++;
  return { token: value.slice(0, end), tail: value.slice(end) };
}

function removeComments(line, state) {
  let visible = "";
  let position = 0;
  while (position < line.length) {
    const boundary = line.indexOf(state.comment ? "-->" : "<!--", position);
    if (boundary === -1) {
      if (!state.comment) visible += line.slice(position);
      break;
    }
    if (!state.comment) visible += line.slice(position, boundary);
    position = boundary + (state.comment ? 3 : 4);
    state.comment = !state.comment;
  }
  return visible;
}

function visibleReadmeLine(rawLine, state) {
  const marker = fenceToken(rawLine);
  if (state.fence) {
    if (marker?.token.startsWith(state.fence) && !marker.tail.trim()) state.fence = null;
    return "";
  }
  if (!state.comment && marker) {
    state.fence = marker.token;
    return "";
  }
  const visible = removeComments(rawLine, state);
  const opening = fenceToken(visible);
  if (opening) state.fence = opening.token;
  return opening ? "" : visible;
}

/** Exclude comments/examples without changing the physical source line indexes. */
function visibleReadmeLines(readme) {
  const state = { fence: null, comment: false };
  const lines = typeof readme === "string" ? readme.split(/\r?\n/) : [];
  // Preserve source positions even when comments or examples are invisible.
  return lines.map((line) => visibleReadmeLine(line, state));
}

function sectionHeading(line) {
  if (!line.startsWith("##") || line[2]?.trim() !== "") return null;
  const text = line.slice(2).trim();
  let end = text.length;
  while (text[end - 1] === "#") end--;
  return text.slice(0, end).trimEnd();
}

function pipeRow(line) {
  const text = line.trim();
  if (!text.startsWith("|") || !text.endsWith("|")) return null;
  const body = text.slice(1, -1);
  const cells = [];
  let cell = "";
  let index = 0;
  while (index < body.length) {
    if (body[index] === "\\" && body[index + 1] === "|") {
      cell += "|";
      index += 2;
      continue;
    }
    if (body[index] === "|") {
      cells.push(cell.trim());
      cell = "";
    } else cell += body[index];
    index++;
  }
  cells.push(cell.trim());
  return cells;
}

function isCatalogHeader(cells) {
  return cells?.length === 3 && cells.map((cell) => cell.toLowerCase()).join("|") === "skill|repository|description";
}

function isSeparator(cells) {
  return cells?.length === 3 && cells.every((cell) => /^:?-{3,}:?$/.test(cell));
}

function scanCatalogLine(line, index, lines, state, result) {
  const heading = sectionHeading(line);
  if (heading !== null) {
    state.inCatalog = heading.toLowerCase() === "available skills";
    result.sections += Number(state.inCatalog);
    state.inTable = false;
    return;
  }
  if (!state.inCatalog || index === state.separatorLine) return;
  const cells = pipeRow(line);
  if (isCatalogHeader(cells) && isSeparator(pipeRow(lines[index + 1] || ""))) {
    state.inTable = true;
    state.separatorLine = index + 1;
    return;
  }
  if (!state.inTable) return;
  if (!cells) {
    state.inTable = false;
    return;
  }
  if (cells.length !== 3 || !cells.every(isText)) {
    result.malformedRows.push(index + 1);
    return;
  }
  const first = cells[0];
  const slug = first.startsWith("`") && first.endsWith("`") ? first.slice(1, -1) : first;
  result.rows.push({ slug, line: index + 1 });
}

function readmeCatalog(readme) {
  const result = { rows: [], sections: 0, malformedRows: [] };
  const state = { inCatalog: false, inTable: false, separatorLine: -1 };
  const lines = visibleReadmeLines(readme);
  for (const [index, line] of lines.entries()) scanCatalogLine(line, index, lines, state, result);
  return result;
}

function canonicalCatalog(marketplace, report) {
  const catalog = new Map();
  if (!Array.isArray(marketplace?.plugins) || !marketplace.plugins.length) {
    report("catalog", "marketplace.plugins", "Expected a nonempty canonical catalog.");
    return catalog;
  }
  for (const plugin of marketplace.plugins) {
    if (!isText(plugin?.name) || catalog.has(plugin.name)) {
      report("catalog", "marketplace.plugins", "Catalog identifiers must be nonempty and unique.", plugin?.name);
    } else catalog.set(plugin.name, plugin);
  }
  return catalog;
}

function checkProvenance(name, slug, row, repo, report) {
  const provenance = row.provenance;
  const checks = [
    ["sourceUrl", isSourceUrl(provenance?.sourceUrl, repo)],
    ["reviewedAt", isReviewDate(provenance?.reviewedAt)],
    ["sourceSnapshotSha256", typeof provenance?.sourceSnapshotSha256 === "string" && /^[a-f\d]{64}$/i.test(provenance.sourceSnapshotSha256)],
  ];
  if (name === "outputs_en") checks.push(["basis", isText(provenance?.basis)]);
  for (const [field, valid] of checks) {
    if (!valid) report("detail-provenance", `${name}.${slug}.provenance.${field}`, "Expected source review provenance with a valid source URL, date, SHA-256 and stated basis.", slug);
  }
  // A snapshot identifies the reviewed source; future fetches are not a CI lock.
}

function checkPresentationRow(name, slug, row, repo, report) {
  const fields = name === "outputs_en" ? ["expectedOutputs"] : ["useCases", "expectedOutputs", "contextRequirements"];
  for (const field of fields) {
    if (!isTextList(row[field])) report("detail-section", `${name}.${slug}.${field}`, "Expected a nonempty array of presentation strings.", slug);
  }
  checkProvenance(name, slug, row, repo, report);
}

function checkMetadataRows(catalog, name, rows, report) {
  if (!isRecord(rows)) {
    report("metadata-shape", name, "Expected a per-entry metadata object.");
    return;
  }
  for (const slug of Object.keys(rows)) {
    if (!DOCUMENTARY_KEYS.has(slug) && !catalog.has(slug)) report("unknown-metadata-entry", `${name}.${slug}`, "Entry is absent from the canonical catalog.", slug);
  }
  const structured = name === "details_de" || name === "outputs_en";
  for (const [slug, plugin] of catalog) {
    const row = rows[slug];
    const valid = structured ? isRecord(row) : isText(row);
    if (!Object.hasOwn(rows, slug) || !valid) {
      report("missing-metadata", `${name}.${slug}`, "A curated source row is required; rendering fallbacks do not count.", slug);
      continue;
    }
    if (structured) checkPresentationRow(name, slug, row, plugin.source?.repo, report);
  }
}

function checkGroupOrder(groups, report) {
  const presentationGroups = isRecord(groups?.groups) ? groups.groups : {};
  const order = Array.isArray(groups?.order) ? groups.order : [];
  const keys = Object.keys(presentationGroups);
  const unknown = order.some((key) => !Object.hasOwn(presentationGroups, key));
  const missingOrDuplicate = keys.some((key) => order.filter((item) => item === key).length !== 1);
  if (!keys.length || unknown || missingOrDuplicate) report("group-order", "groups.order", "Every presentation group must occur exactly once in the rendered order.");
  return presentationGroups;
}

function reportMembership(counts, code, path, message, report) {
  for (const [slug, count] of counts) {
    if (count !== 1) report(code, path, `${message}; found ${count}.`, slug);
  }
}

function checkGroups(catalog, groups, report) {
  const counts = new Map([...catalog.keys()].map((slug) => [slug, 0]));
  const presentationGroups = checkGroupOrder(groups, report);
  for (const [key, group] of Object.entries(presentationGroups)) {
    if (!Array.isArray(group?.slugs)) {
      report("group-shape", `groups.groups.${key}.slugs`, "Expected an array of catalog identifiers.");
      continue;
    }
    for (const slug of group.slugs) {
      if (!catalog.has(slug)) report("unknown-group-entry", `groups.groups.${key}.slugs`, "Group contains an entry absent from the canonical catalog.", slug);
      else counts.set(slug, counts.get(slug) + 1);
    }
  }
  reportMembership(counts, "group-membership", "groups.groups", "Expected exactly one presentation group", report);
}

function checkReadme(catalog, readme, report) {
  const entries = readmeCatalog(readme);
  if (entries.sections !== 1) report("readme-section", "README.md", "Expected exactly one Available Skills section.");
  const counts = new Map([...catalog.keys()].map((slug) => [slug, 0]));
  for (const line of entries.malformedRows) report("readme-table-shape", `README.md:${line}`, "Expected three nonempty catalog table cells.");
  for (const { slug, line } of entries.rows) {
    if (!catalog.has(slug)) report("unknown-readme-entry", `README.md:${line}`, "Table entry is absent from the canonical catalog.", slug);
    else counts.set(slug, counts.get(slug) + 1);
  }
  reportMembership(counts, "readme-membership", "README.md", "Expected one Available Skills table row", report);
}

/**
 * Audit authored source coverage before rendering fallbacks can hide missing rows.
 * Both locale presentation maps are mandatory. Provenance identifies reviewed
 * snapshots; it deliberately does not lock CI to a future fetched README hash.
 * @param {object} sources Canonical catalog, authored maps, groups and README text.
 * @returns {Array<{code: string, path: string, message: string, slug?: string}>}
 */
export function checkCatalogMetadata({ marketplace, displayNames, descriptionsDe, detailsDe, outputsEn, groups, readme }) {
  const issues = [];
  const report = (code, path, message, slug) => issues.push({ code, path, message, ...(slug ? { slug } : {}) });
  const catalog = canonicalCatalog(marketplace, report);
  if (!catalog.size) return issues;
  for (const [name, rows] of [["displayNames", displayNames], ["descriptions_de", descriptionsDe], ["details_de", detailsDe], ["outputs_en", outputsEn]]) {
    checkMetadataRows(catalog, name, rows, report);
  }
  checkGroups(catalog, groups, report);
  checkReadme(catalog, readme, report);
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
    outputsEn: json("src/_data/outputs_en.json"),
    groups,
    readme: readFileSync(resolve(siteRoot, "../README.md"), "utf8"),
  });
  console.log(`Catalog metadata check: ${marketplace.plugins.length} entries, ${issues.length} issue(s)`);
  for (const { path, message, slug } of issues) {
    const location = slug ? `${path} [${slug}]` : path;
    console.error(`  ${location}: ${message}`);
  }
  if (issues.length) process.exitCode = 1;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    await main();
  } catch (error) {
    console.error(`Catalog metadata check failed: ${error.message}`);
    process.exitCode = 1;
  }
}
