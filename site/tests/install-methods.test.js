// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Netresearch DTT GmbH
import assert from "node:assert/strict";
import test from "node:test";
import { readFileSync } from "node:fs";
import loadSkills from "../src/_data/skills.js";
import { resolveInstallCommand } from "../src/_data/_helpers/install-command.js";
import methods from "../src/_data/installMethods.js";
import loadSearchIndex from "../src/_data/searchIndex.js";
import { parseReadme } from "../scripts/parse-readme.js";

const marketplace = JSON.parse(readFileSync(new URL("../../.claude-plugin/marketplace.json", import.meta.url)));
const skills = loadSkills();

test("the published PHP engine installs without activating Composer plugins", () => {
  const skill = skills.find(({ slug }) => slug === "php-structured-edit");
  const command = skill.installCommands["composer-require"];
  assert.equal(command, "composer require --dev --no-plugins --no-scripts netresearch/php-ast-edit-skill:^2.0");
  assert.doesNotMatch(command, /dev-main|repositories\./);
  assert.equal(command.includes("\n"), false);
  for (const language of ["en", "de"]) {
    assert.ok(skill.installLinkLabel[language]);
    for (const { id } of methods.methods) {
      const hint = skill.installHints[id][language];
      assert.equal(hint.linkUrl, "https://github.com/netresearch/php-ast-edit-skill/blob/main/docs/installation.md");
      assert.ok(hint.text && hint.linkText && hint.suffix);
    }
    assert.equal(skill.installHints["composer-require"][language].prerequisite, null);
    assert.match(skill.installHints["claude-code"][language].prerequisite, /\/plugin marketplace add netresearch\/claude-code-marketplace/);
    assert.match(skill.installHints.npx[language].prerequisite, /Node\.js 22\.20\+/);
  }
});

test("an unavailable Composer package stays unavailable while supported routes remain", () => {
  const skill = skills.find(({ slug }) => slug === "cli-tools");
  assert.equal(skill.installCommands["composer-require"], null);
  assert.equal(skill.installCommands["composer-skills"], "composer skills:add netresearch/coding_agent_cli_toolset");
  assert.equal(skill.installCommands.npx, "npx skills add https://github.com/netresearch/coding_agent_cli_toolset");
  for (const language of ["en", "de"]) {
    assert.ok(skill.installHints["composer-require"][language].text);
    assert.equal(skill.installHints["composer-require"][language].prerequisite, null);
  }
});

test("interactive npx selection uses source skill names for bundles", () => {
  for (const [slug, repo] of [["jira-integration", "jira-skill"], ["orocommerce", "orocommerce-skill"]]) {
    assert.equal(skills.find((skill) => skill.slug === slug).installCommands.npx,
      `npx skills add https://github.com/netresearch/${repo}`);
  }
});

test("an ordinary package keeps all supported installation routes", () => {
  const skill = skills.find(({ slug }) => slug === "concourse-ci");
  assert.deepEqual(skill.installCommands, {
    "claude-code": `/plugin install concourse-ci@${marketplace.name}`,
    npx: "npx skills add https://github.com/netresearch/concourse-ci-skill",
    "composer-require": "composer require netresearch/concourse-ci-skill",
    "composer-skills": "composer skills:add netresearch/concourse-ci-skill",
  });
});

test("explicit null is supported but malformed command overrides are rejected", () => {
  const method = methods.methods.find(({ id }) => id === "npx");
  const skill = { slug: "example", repo: "netresearch/example" };
  assert.equal(resolveInstallCommand(method, skill, marketplace, { command: null }), null);
  assert.equal(resolveInstallCommand(method, skill, marketplace, {}),
    "npx skills add https://github.com/netresearch/example");
  for (const command of [false, 42, "", "  ", [], {}]) {
    assert.throws(() => resolveInstallCommand(method, skill, marketplace, { command }), TypeError);
  }
});

test("every German record has complete localized details and never reuses English descriptions", () => {
  assert.equal(skills.length, marketplace.plugins.length);
  for (const skill of skills) {
    assert.notEqual(skill.descriptionDe, skill.descriptionEn, skill.slug);
    for (const key of ["useCasesDe", "expectedOutputsDe", "contextRequirementsDe"]) {
      assert.ok(Array.isArray(skill[key]) && skill[key].length > 0, `${skill.slug}.${key}`);
      assert.ok(skill[key].every((item) => typeof item === "string" && item.trim()), `${skill.slug}.${key}`);
    }
    assert.match(skill.detailProvenanceDe.sourceSnapshotSha256, /^[a-f0-9]{64}$/);
    for (const key of ["hasSourceUseCases", "hasSourceExpectedOutputs", "hasSourceContextRequirements"]) {
      assert.equal(typeof skill[key], "boolean", `${skill.slug}.${key}`);
    }
  }
});

test("the German search index uses German use cases while English records keep sourced data", () => {
  const search = loadSearchIndex();
  for (const skill of skills) {
    assert.deepEqual(search.de.find(({ slug }) => slug === skill.slug).useCases, skill.useCasesDe, skill.slug);
    assert.deepEqual(search.en.find(({ slug }) => slug === skill.slug).useCases, skill.useCases, skill.slug);
  }
});

test("every package describes an outcome in both locales and keeps parsed English outputs first", () => {
  const summaries = JSON.parse(readFileSync(new URL("../src/_data/outputs_en.json", import.meta.url)));
  for (const skill of skills) {
    for (const items of [skill.expectedOutputs, skill.expectedOutputsDe]) {
      assert.ok(items.length > 0, skill.slug);
      assert.ok(items.every((item) => typeof item === "string" && item.trim()), skill.slug);
      assert.ok(items.every((item) => !item.startsWith("Ein eigener Ergebnisabschnitt")), skill.slug);
    }
    if (skill.hasSourceExpectedOutputs) {
      const cache = JSON.parse(readFileSync(new URL(`../cache/skills-readme/${skill.slug}.json`, import.meta.url)));
      assert.deepEqual(skill.expectedOutputs, cache.parsed.expectedOutputs, skill.slug);
    } else {
      assert.deepEqual(skill.expectedOutputs, summaries[skill.slug].expectedOutputs, skill.slug);
    }
    assert.match(skill.outputProvenanceEn.sourceSnapshotSha256, /^[a-f0-9]{64}$/);
  }
});

test("explicit context requirements take priority over earlier installation notices", () => {
  const parsed = parseReadme(`# PHP editing tool

## Installation

When reviewing this change before it merges, run commands from the reviewed checkout.
Published archives remain unchanged until a subsequent release.

## Context requirements

Provide the target file paths, intended change, and a writable working tree.

## Expected outputs

- A guarded edit and a measured diff.
`);
  assert.deepEqual(parsed.contextRequirements, [
    "Provide the target file paths, intended change, and a writable working tree.",
  ]);
  assert.deepEqual(parsed.expectedOutputs, ["A guarded edit and a measured diff."]);
});

// The orocommerce-skill README as fetched on 2026-10-22: its Installation
// section opens with a fenced block, and its Requirements section comes later.
const orocommerceReadme = readFileSync(new URL("./fixtures/orocommerce-skill-README.md", import.meta.url), "utf8");

test("a real README's requirements section wins over its earlier installation commands (#132)", () => {
  const parsed = parseReadme(orocommerceReadme);
  assert.deepEqual(parsed.contextRequirements, [
    "[Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI",
  ]);
});

test("a README without a requirements section shows no context requirements (#132)", () => {
  const withoutRequirements = orocommerceReadme.replace(/^## Requirements\n[\s\S]*?(?=^## )/m, "");
  assert.notEqual(withoutRequirements, orocommerceReadme);
  assert.match(withoutRequirements, /^## Installation$/m);
  assert.deepEqual(parseReadme(withoutRequirements).contextRequirements, []);
});

test("installation, setup and dependency sections are not context requirements", () => {
  for (const heading of ["Installation", "Setup", "Dependencies"]) {
    const parsed = parseReadme(`## ${heading}\n\n- composer require vendor/skill\n`);
    assert.deepEqual(parsed.contextRequirements, [], heading);
  }
});

test("context extraction keeps the requirement aliases and document order", () => {
  for (const heading of ["Requirements", "Prerequisites", "Context", "What this skill needs"]) {
    const parsed = parseReadme(`## Installation\n\n- composer require vendor/skill\n\n## ${heading}\n\n- PHP 8.2 and Composer.\n\n## Context\n\n- A later fallback.\n`);
    assert.deepEqual(parsed.contextRequirements, ["PHP 8.2 and Composer."], heading);
  }
});

test("ordered requirement lists become one item per entry", () => {
  const parsed = parseReadme("## Requirements\n\n1. PHP 8.2\n2) Composer\n");
  assert.deepEqual(parsed.contextRequirements, ["PHP 8.2", "Composer"]);
});

test("an empty explicit context section falls back to an earlier requirements section", () => {
  const parsed = parseReadme("## Requirements\n\nPHP 8.2 and Composer.\n\n## Context requirements\n\n## Outputs\n\nA diff.\n");
  assert.deepEqual(parsed.contextRequirements, ["PHP 8.2 and Composer."]);
});

test("an empty explicit context section does not hide a later requirements section", () => {
  const parsed = parseReadme("## Context requirements\n\n## Prerequisites\n\nPHP 8.2 and Composer.\n\n## Outputs\n\nA diff.\n");
  assert.deepEqual(parsed.contextRequirements, ["PHP 8.2 and Composer."]);
});

test("related-skill links outside the link allowlist are dropped", () => {
  const parsed = parseReadme([
    "## Related skills",
    "",
    "- [Script](javascript:alert%28document.domain%29)",
    "- [Tabbed](java\tscript:alert(1))",
    "- [Data](data:text/html,x)",
    "- [Harness](https://github.com/netresearch/agent-harness-skill)",
    "- [Local](../docs/)",
    "",
  ].join("\n"));
  assert.deepEqual(parsed.relatedSkills.map(({ href }) => href), [
    "https://github.com/netresearch/agent-harness-skill",
    "../docs/",
  ]);
  assert.equal(parsed.relatedSkills[0].slug, "agent-harness");
});
