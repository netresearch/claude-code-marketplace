// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Netresearch DTT GmbH
import assert from "node:assert/strict";
import test from "node:test";
import { readFileSync } from "node:fs";
import loadSkills from "../src/_data/skills.js";
import methods from "../src/_data/installMethods.js";
import { parseReadme } from "../scripts/parse-readme.js";

const marketplace = JSON.parse(readFileSync(new URL("../../.claude-plugin/marketplace.json", import.meta.url)));
const skills = loadSkills();

test("the PHP engine has a VCS installation route without plugin activation", () => {
  const skill = skills.find(({ slug }) => slug === "php-structured-edit");
  const command = skill.installCommands["composer-require"];
  assert.match(command, /composer config repositories\.php-ast-edit vcs https:\/\/github\.com\/netresearch\/php-ast-edit-skill/);
  assert.match(command, /composer require --dev --no-plugins --no-scripts netresearch\/php-ast-edit-skill:dev-main/);
  // Cards use white-space: nowrap and copy innerText, which collapses newlines.
  // Keep the two commands connected even after browser whitespace normalization.
  assert.match(command, /\.git && composer require /);
  assert.equal(command.includes("\n"), false);
  for (const language of ["en", "de"]) {
    assert.ok(skill.installLinkLabel[language]);
    for (const { id } of methods.methods) {
      const hint = skill.installHints[id][language];
      assert.equal(hint.linkUrl, "https://github.com/netresearch/php-ast-edit-skill#installation");
      assert.ok(hint.text && hint.linkText && hint.suffix);
    }
  }
});

test("other skills retain every default install command and hint", () => {
  for (const skill of skills.filter(({ slug }) => slug !== "php-structured-edit")) {
    for (const method of methods.methods) {
      assert.equal(skill.installCommands[method.id], method.command(skill, marketplace), skill.slug);
      assert.deepEqual(skill.installHints[method.id], method.hint, skill.slug);
    }
    assert.equal(skill.installLinkLabel, null, skill.slug);
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
