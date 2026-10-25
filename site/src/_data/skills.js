// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Netresearch DTT GmbH
/**
 * Canonical skills array — merges marketplace.json (Tier 1) with cached parsed
 * Skill-Repo READMEs (Tier 2) and category/group metadata.
 *
 * AGENTS.md §Required fields per skill entry: every skill needs 13 fields.
 * Where source data is missing, this module returns plain empty values
 * (empty arrays for lists, null for scalars) — check-orphans.js then
 * decides whether the gap is fatal, advisory, or absorbed by a
 * documented entry in _data/overrides.json (AGENTS.md §Known marketplace
 * overrides). The structured-error shape is intentionally NOT used here;
 * it would complicate every template that consumes the data.
 */
import { readFileSync, existsSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const MARKETPLACE = resolve(__dirname, "../../../.claude-plugin/marketplace.json");
const CACHE_DIR = resolve(__dirname, "../../cache/skills-readme");

import categories from "./categories.js";
import valueTypes from "./valueTypes.js";
import groups from "./groups.js";
import descriptionsDe from "./descriptions_de.json" with { type: "json" };
import detailsDe from "./details_de.json" with { type: "json" };
import { displayName } from "./_helpers/display-name.js";
import { resolveInstallCommand } from "./_helpers/install-command.js";
import installMethods from "./installMethods.js";
import installOverrides from "./installOverrides.json" with { type: "json" };

function loadCache(slug) {
  const p = resolve(CACHE_DIR, `${slug}.json`);
  if (!existsSync(p)) return null;
  try {
    return JSON.parse(readFileSync(p, "utf8"));
  } catch {
    return null;
  }
}

function groupOf(slug) {
  for (const [groupKey, group] of Object.entries(groups.groups)) {
    if (group.slugs.includes(slug)) return groupKey;
  }
  return null;
}

function deriveRelatedFromGroup(slug, allSkills) {
  const myGroup = groupOf(slug);
  if (!myGroup) return [];
  return allSkills
    .filter((s) => s.slug !== slug && groupOf(s.slug) === myGroup)
    .slice(0, 4)
    .map((s) => ({ slug: s.slug, source: "derived-group" }));
}

function deriveTagsFromCategoryAndGroup(skill) {
  const tags = new Set([skill.category]);
  const g = groupOf(skill.slug);
  if (g) tags.add(g);
  if (skill.slug.startsWith("typo3-")) tags.add("typo3");
  if (skill.slug.startsWith("github-")) tags.add("github");
  return [...tags];
}


function resolveInstallHint(method, override) {
  if (!override || !Object.hasOwn(override, "hint")) return method.hint;
  if (override.hint === null) return null;
  if (typeof override.hint !== "object" || Array.isArray(override.hint)) {
    throw new TypeError(`Invalid installation hint for ${method.id}`);
  }
  // Keep generic prerequisites when a package replaces its explanatory copy.
  // An engine-only route can explicitly clear prerequisite with null.
  return Object.fromEntries(["en", "de"].map((lang) => [lang, {
    ...method.hint?.[lang],
    ...override.hint[lang],
  }]));
}

export default function () {
  const marketplace = JSON.parse(readFileSync(MARKETPLACE, "utf8"));

  const skills = marketplace.plugins.map((plugin) => {
    const cache = loadCache(plugin.name);
    const parsed = cache?.parsed || null;
    const localized = detailsDe[plugin.name];
    if (typeof descriptionsDe[plugin.name] !== "string" || !descriptionsDe[plugin.name].trim()) {
      throw new Error(`Missing German description for ${plugin.name}`);
    }
    for (const field of ["useCases", "expectedOutputs", "contextRequirements"]) {
      if (!Array.isArray(localized?.[field]) || !localized[field].length
          || !localized[field].every((item) => typeof item === "string" && item.trim())) {
        throw new Error(`Missing German detail field ${plugin.name}/${field}`);
      }
    }

    // Build install-command map once per skill so templates can just key by
    // method id instead of recomputing strings per render.
    const skillStub = {
      slug: plugin.name,
      repo: plugin.source?.repo,
    };
    const installOverride = installOverrides[plugin.name] || {};
    const installCommands = Object.fromEntries(
      installMethods.methods.map((m) => [
        m.id,
        resolveInstallCommand(m, skillStub, marketplace, installOverride.methods?.[m.id]),
      ])
    );
    const installHints = Object.fromEntries(
      installMethods.methods.map((m) => [m.id, resolveInstallHint(m, installOverride.methods?.[m.id])])
    );

    return {
      slug: plugin.name,
      displayName: displayName(plugin.name),
      description: plugin.description,
      descriptionEn: plugin.description,
      descriptionDe: descriptionsDe[plugin.name],
      readmeLead: parsed?.readmeLead || null,
      category: plugin.category,
      categoryLabelEn: categories.labels.en[plugin.category],
      categoryLabelDe: categories.labels.de[plugin.category],
      valueType: plugin.value_type || null,
      valueTypeLabelEn: plugin.value_type ? valueTypes.labels.en[plugin.value_type] : null,
      valueTypeLabelDe: plugin.value_type ? valueTypes.labels.de[plugin.value_type] : null,
      group: groupOf(plugin.name),
      repo: plugin.source?.repo,
      repoUrl: plugin.source?.repo ? `https://github.com/${plugin.source.repo}` : null,
      readmeUrl: plugin.source?.repo
        ? `https://github.com/${plugin.source.repo}#readme`
        : null,
      skillsShUrl: plugin.source?.repo
        ? `https://www.skills.sh/${plugin.source.repo}`
        : null,
      installCommand: installCommands["claude-code"],
      npxCommand: installCommands["npx"],
      installCommands,
      installHints,
      installLinkLabel: installOverride.linkLabel || null,
      canonicalUrlEn: `/en/skills/${plugin.name}/`,
      canonicalUrlDe: `/de/skills/${plugin.name}/`,
      useCases: parsed?.useCases?.length ? parsed.useCases : [],
      expectedOutputs: parsed?.expectedOutputs?.length ? parsed.expectedOutputs : [],
      contextRequirements: parsed?.contextRequirements?.length
        ? parsed.contextRequirements
        : [],
      hasSourceUseCases: Boolean(parsed?.useCases?.length),
      hasSourceExpectedOutputs: Boolean(parsed?.expectedOutputs?.length),
      hasSourceContextRequirements: Boolean(parsed?.contextRequirements?.length),
      useCasesDe: localized.useCases,
      expectedOutputsDe: localized.expectedOutputs,
      contextRequirementsDe: localized.contextRequirements,
      detailProvenanceDe: localized.provenance,
      tags: parsed?.tags?.length ? parsed.tags : [],
      relatedSkills: parsed?.relatedSkills?.length ? parsed.relatedSkills : [],
      readmeFetchedAt: cache?.fetchedAt || null,
      version: cache?.latestRelease?.tag || null,
      versionPublishedAt: cache?.latestRelease?.publishedAt || null,
      versionUrl: cache?.latestRelease?.htmlUrl || null,
    };
  });

  for (const skill of skills) {
    if (!skill.relatedSkills.length) {
      skill.relatedSkills = deriveRelatedFromGroup(skill.slug, skills);
    }
    if (!skill.tags.length) {
      skill.tags = deriveTagsFromCategoryAndGroup(skill);
    }
    if (!skill.useCases.length && skill.description) {
      skill.useCases = deriveUseCasesFromDescription(skill.description);
    }
  }

  return skills;
}

function deriveUseCasesFromDescription(description) {
  // Marketplace descriptions are dense single paragraphs. Split on ". " into
  // sentence-sized bullets and drop leading boilerplate ("By Netresearch.").
  return description
    .split(/(?<=[.!?])\s+/)
    .map((s) => s.trim().replace(/\.$/, ""))
    .filter((s) => s.length > 8 && !/^by\s+netresearch/i.test(s));
}
