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

test("context extraction retains existing fallback aliases and document order", () => {
  for (const heading of ["Installation", "Requirements", "Setup", "Dependencies"]) {
    const parsed = parseReadme(`## ${heading}\n\n- PHP 8.2 and Composer.\n\n## Context\n\n- A later fallback.\n`);
    assert.deepEqual(parsed.contextRequirements, ["PHP 8.2 and Composer."], heading);
  }
});

test("an empty explicit context section retains installation fallback", () => {
  const parsed = parseReadme("## Installation\n\nPHP 8.2 and Composer.\n\n## Context requirements\n\n## Outputs\n\nA diff.\n");
  assert.deepEqual(parsed.contextRequirements, ["PHP 8.2 and Composer."]);
});
