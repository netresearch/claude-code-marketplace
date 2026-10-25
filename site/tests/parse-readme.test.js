// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Netresearch DTT GmbH
import assert from "node:assert/strict";
import test from "node:test";
import { parseReadme } from "../scripts/parse-readme.js";

// Verbatim section excerpts from the source READMEs frozen on 2026-10-25.
// Keep fixtures local: the regression suite never fetches live repositories.
const siteConformance = [
  "## Use when",
  "",
  '- A repository has `composer.json` `"type": "project"` **and** a root Compose',
  "  file (`compose.yaml`/`docker-compose.yml`).",
  "- You are reviewing or hardening container/Compose topology, a Concourse",
  "  pipeline, supply-chain gating, or TYPO3 site config (`config/system`,",
  "  `config/sites`).",
  "",
  "## Expected outputs",
  "",
  "- A pass/fail conformance verdict per rule family (STRUCT, CONTAINER, CI,",
  "  DEPLOY, DEP, SEC, DOC) with file:line evidence.",
  "- For migrations: the concrete seven-move transformation plan",
  "  (`references/migration-from-reference.md`).",
  "",
  "## Context requirements",
  "",
  "- Read access to the target repository tree (`composer.json`, `Dockerfile`,",
  "  `compose*.yaml`, `ci/`, `config/system`, `config/sites`, `.gitlab-ci.yml`,",
  "  `AGENTS.md`).",
  "- `python3` + `pyyaml` to run the bundled checker. Nothing else.",
].join("\n");

test("Use when preserves source scenarios and their wrapped scope", () => {
  assert.deepEqual(parseReadme(siteConformance).useCases, [
    'A repository has `composer.json` `"type": "project"` **and** a root Compose file (`compose.yaml`/`docker-compose.yml`).',
    "You are reviewing or hardening container/Compose topology, a Concourse pipeline, supply-chain gating, or TYPO3 site config (`config/system`, `config/sites`).",
  ]);
});

test("wrapped output and prerequisite items retain paths, evidence and qualifiers", () => {
  const parsed = parseReadme(siteConformance);
  assert.deepEqual(parsed.expectedOutputs, [
    "A pass/fail conformance verdict per rule family (STRUCT, CONTAINER, CI, DEPLOY, DEP, SEC, DOC) with file:line evidence.",
    "For migrations: the concrete seven-move transformation plan (`references/migration-from-reference.md`).",
  ]);
  assert.deepEqual(parsed.contextRequirements, [
    "Read access to the target repository tree (`composer.json`, `Dockerfile`, `compose*.yaml`, `ci/`, `config/system`, `config/sites`, `.gitlab-ci.yml`, `AGENTS.md`).",
    "`python3` + `pyyaml` to run the bundled checker. Nothing else.",
  ]);
});

test("TypoScript reference retains first-run network and version fallback limits", () => {
  const parsed = parseReadme([
    "## Context requirements",
    "",
    "- Network access on first run (`scripts/lookup.sh --update`); all lookups are",
    "  served from the local cache afterwards",
    "- A `composer.json` or `composer.lock` in the project for automatic TYPO3",
    "  version detection from `typo3/cms-core` (without it, the lookup uses",
    "  `main`, the development branch of the upstream documentation)",
  ].join("\n"));
  assert.deepEqual(parsed.contextRequirements, [
    "Network access on first run (`scripts/lookup.sh --update`); all lookups are served from the local cache afterwards",
    "A `composer.json` or `composer.lock` in the project for automatic TYPO3 version detection from `typo3/cms-core` (without it, the lookup uses `main`, the development branch of the upstream documentation)",
  ]);
});

test("Retro's tool table becomes prerequisite statements, not pipe-delimited Markdown", () => {
  const parsed = parseReadme([
    "## Requirements",
    "",
    "| Tool | Used for |",
    "|---|---|",
    "| Claude Code | The host that runs the plugin and the `/retro` command |",
    "| `python3` | Mechanical pre-pass and the cross-session scan |",
    "| `uv` | Session scope and review feedback (`derive-session-scope.py`, `collect-review-findings.py`): installs the shell parser tree-sitter-bash the scripts declare; the first run downloads it |",
    "| `jq` | Skill discovery, manifest parsing, and the optional hook |",
    "| `gh` and/or `glab` | Creating pull/merge requests for skill updates |",
    "| `git` | Cloning source repos and materializing changes |",
  ].join("\n"));
  assert.deepEqual(parsed.contextRequirements, [
    "Claude Code: The host that runs the plugin and the `/retro` command",
    "`python3`: Mechanical pre-pass and the cross-session scan",
    "`uv`: Session scope and review feedback (`derive-session-scope.py`, `collect-review-findings.py`): installs the shell parser tree-sitter-bash the scripts declare; the first run downloads it",
    "`jq`: Skill discovery, manifest parsing, and the optional hook",
    "`gh` and/or `glab`: Creating pull/merge requests for skill updates",
    "`git`: Cloning source repos and materializing changes",
  ]);
});

test("mixed requirements retain table tools and wrapped list prerequisites in source order", () => {
  const parsed = parseReadme([
    "## Requirements", "",
    "| Tool | Minimum version |", "| --- | --- |",
    "| PHP | 8.2+ |", "| Composer | 2.7+ |", "",
    "- Read access to the repository,",
    "  including source code and tests.",
  ].join("\n"));
  assert.deepEqual(parsed.contextRequirements, [
    "PHP: 8.2+",
    "Composer: 2.7+",
    "Read access to the repository, including source code and tests.",
  ]);
});

test("a requirements table between list blocks does not reorder or discard either list", () => {
  const parsed = parseReadme([
    "## Context requirements", "", "- A writable working tree.", "",
    "| Tool | Purpose |", "| --- | --- |", "| `python3` | Run the checker. |", "",
    "- Network access on first run only.",
  ].join("\n"));
  assert.deepEqual(parsed.contextRequirements, [
    "A writable working tree.",
    "`python3`: Run the checker.",
    "Network access on first run only.",
  ]);
});

test("standalone Python prerequisite before a tool table remains discovery metadata", () => {
  // Reproduce the reviewed mixed-form Requirements section without network I/O.
  const parsed = parseReadme([
    "## Requirements", "", "Python 3.11 is required.", "",
    "| Tool | Purpose |", "| --- | --- |", "| uv | Run scripts. |",
  ].join("\n"));
  assert.deepEqual(parsed.contextRequirements, [
    "Python 3.11 is required.",
    "uv: Run scripts.",
  ]);
});

test("mixed prerequisite prose before, after and between tables and lists stays in source order", () => {
  const parsed = parseReadme([
    "## Context requirements", "", "Python 3.11 is required.",
    "Network access is needed on the first run.", "",
    "| Tool | Purpose |", "| --- | --- |", "| uv | Run scripts. |", "",
    "A writable project directory is required.", "",
    "- Read access to the repository,", "  including source code and tests.", "",
    "The selected repository must contain", "a composer.json file.", "",
    "| Tool | Minimum version |", "| --- | --- |", "| PHP | 8.2+ |", "",
    "Credentials must permit reading project issues.",
  ].join("\n"));
  assert.deepEqual(parsed.contextRequirements, [
    "Python 3.11 is required. Network access is needed on the first run.",
    "uv: Run scripts.",
    "A writable project directory is required.",
    "Read access to the repository, including source code and tests.",
    "The selected repository must contain a composer.json file.",
    "PHP: 8.2+",
    "Credentials must permit reading project issues.",
  ]);
});

test("mixed output summaries retain standalone deliverables and do not duplicate nested qualifiers", () => {
  const parsed = parseReadme([
    "## Expected outputs", "", "A report records every checked file.",
    "| Artifact | Purpose |", "| --- | --- |", "| findings.json | Machine-readable evidence. |",
    "A summary names the remaining risks.", "",
    "- A proposed patch with:", "  - File and line evidence", "    for each change.", "",
    "A reviewer receives the final action list.",
  ].join("\n"));
  assert.deepEqual(parsed.expectedOutputs, [
    "A report records every checked file.",
    "findings.json: Machine-readable evidence.",
    "A summary names the remaining risks.",
    "A proposed patch with: File and line evidence for each change.",
    "A reviewer receives the final action list.",
  ]);
});

test("mixed requirements exclude generic introductions and fenced examples while keeping concrete prose", () => {
  const parsed = parseReadme([
    "## Requirements", "", "The following tools are required:", "",
    "| Tool | Purpose |", "| --- | --- |", "| uv | Run scripts. |", "",
    "Run the following:", "", "```sh", "install example-only-tool", "```", "",
    "- Read access to the repository:", "  - Include tests", "    and configuration files.", "",
    "For E2EE support, install libolm:", "", "```sh", "sudo apt install libolm-dev", "```", "",
    "Network access is required for the first download.",
  ].join("\n"));
  assert.deepEqual(parsed.contextRequirements, [
    "uv: Run scripts.",
    "Read access to the repository: Include tests and configuration files.",
    "For E2EE support, install libolm.",
    "Network access is required for the first download.",
  ]);
});

test("generic installation and requirement table lead-ins never become prerequisites", () => {
  for (const intro of [
    "This skill requires the following tools:",
    "Install these tools:",
    "The skill needs the following dependencies:",
    "Install the following packages:",
  ]) {
    const parsed = parseReadme([
      "## Requirements", "", intro, "",
      "| Tool | Purpose |", "| --- | --- |", "| uv | Run scripts. |",
    ].join("\n"));
    assert.deepEqual(parsed.contextRequirements, ["uv: Run scripts."], intro);
  }
});

test("a nested requirement table appears once without raw pipe syntax in its parent bullet", () => {
  // Tool names and purpose text are the frozen Retro README's requirement rows;
  // nesting them under a list item exercises the independently reported failure.
  const parsed = parseReadme([
    "## Requirements", "", "- Review workflow tools:", "",
    "  | Tool | Used for |", "  | --- | --- |",
    "  | Claude Code | The host that runs the plugin and the `/retro` command |",
    "  | `python3` | Mechanical pre-pass and the cross-session scan |", "",
    "- Read access to the repository.",
  ].join("\n"));
  assert.deepEqual(parsed.contextRequirements, [
    "Review workflow tools:",
    "Claude Code: The host that runs the plugin and the `/retro` command",
    "`python3`: Mechanical pre-pass and the cross-session scan",
    "Read access to the repository.",
  ]);
});

test("Matrix's platform setup block leaves a complete libolm requirement", () => {
  const parsed = parseReadme([
    "## Prerequisites",
    "",
    "**For E2EE support** (most Matrix rooms), install libolm:",
    "",
    "```bash",
    "sudo apt install libolm-dev    # Debian/Ubuntu",
    "sudo dnf install libolm-devel  # Fedora",
    "brew install libolm            # macOS",
    "```",
  ].join("\n"));
  assert.deepEqual(parsed.contextRequirements, [
    "**For E2EE support** (most Matrix rooms), install libolm.",
  ]);
});

test("explicit use cases win over an earlier generic Features section", () => {
  assert.deepEqual(parseReadme([
    "## Features", "", "- General feature.", "",
    "## Quick Start", "", "- Setup step.", "",
    "## Use when", "", "- Review a TYPO3 site.",
  ].join("\n")).useCases, ["Review a TYPO3 site."]);
});

test("nested feature qualifiers stay attached to their parent item", () => {
  const parsed = parseReadme([
    "## Features", "",
    "- **SKILL.md** - Complete brand implementation guide covering:",
    "  - Brand identity and core values",
    "  - Color system with accessibility compliance",
    "    and typography standards",
    "- Separate reference documentation",
  ].join("\n"));
  assert.deepEqual(parsed.useCases, [
    "**SKILL.md** - Complete brand implementation guide covering: Brand identity and core values; Color system with accessibility compliance and typography standards",
    "Separate reference documentation",
  ]);
});

test("fenced example headings and bullets never become discovery metadata", () => {
  for (const fence of ["```", "~~~~"]) {
    const parsed = parseReadme([
      "# Example", "", fence + "markdown",
      "## Requirements", "", "- A fake prerequisite.", "",
      "## Related skills", "", "- [Fake](https://example.com/fake)",
      fence, "", "## Requirements", "", "- PHP 8.2.",
      "", "## Expected outputs", "", "- A diff.",
      "", fence + "text", "- This is example output, not a deliverable.", fence,
    ].join("\n"));
    assert.deepEqual(parsed.contextRequirements, ["PHP 8.2."]);
    assert.deepEqual(parsed.expectedOutputs, ["A diff."]);
    assert.deepEqual(parsed.relatedSkills, []);
  }
});

test("code-only sections and generic incomplete code lead-ins remain absent", () => {
  for (const lead of ["", "Run the following:"]) {
    const parsed = parseReadme([
      "## Prerequisites", "", lead, "", "```sh", "install tool", "```",
    ].join("\n"));
    assert.deepEqual(parsed.contextRequirements, []);
  }
});

test("source tables retain escaped pipes and code without splitting cells", () => {
  const parsed = parseReadme([
    "## Requirements", "", "| Tool | Use | Version |", "| --- | --- | --- |",
    "| `a|b` | Match a\\|b | 2+ |",
  ].join("\n"));
  assert.deepEqual(parsed.contextRequirements, ["`a|b`: Use: Match a|b; Version: 2+"]);
});

test("untrusted markup stays text and dangerous related URL schemes stay rejected", () => {
  const parsed = parseReadme([
    "## Expected outputs", "", "- `<script>alert(1)</script>` stays a code sample.",
    "", "## Related skills", "",
    "- [Script](javascript:alert%281%29)",
    "- [Obfuscated](java\tscript:alert%281%29)",
    "- [Data](data:text/html,payload)",
    "- [Safe](https://github.com/netresearch/file-search-skill)",
  ].join("\n"));
  assert.deepEqual(parsed.expectedOutputs, ["`<script>alert(1)</script>` stays a code sample."]);
  assert.deepEqual(parsed.relatedSkills, [{
    label: "Safe", href: "https://github.com/netresearch/file-search-skill", slug: "file-search",
  }]);
});

test("standalone comments are hidden, while inline code markers remain source text", () => {
  const parsed = parseReadme([
    "<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->", "", "# Tool", "", "A real description.",
    "", "<!--", "## Requirements", "- A commented-out prerequisite.", "-->",
    "", "## Expected outputs", "", "- Preserve `<!-- SLOT -->` markers in the template.",
  ].join("\n"));
  assert.equal(parsed.readmeLead, "A real description.");
  assert.deepEqual(parsed.contextRequirements, []);
  assert.deepEqual(parsed.expectedOutputs, ["Preserve `<!-- SLOT -->` markers in the template."]);
});

test("a closed comment followed by prose never consumes a later genuine section", () => {
  const parsed = parseReadme([
    "# Tool", "", "<!-- note --> A genuine source description.", "",
    "## Requirements", "", "- PHP 8.2 and read access.", "",
    "<!-- A separate later comment. -->",
  ].join("\n"));
  assert.deepEqual(parsed.contextRequirements, ["PHP 8.2 and read access."]);
  assert.equal(parsed.readmeLead, "A genuine source description.");
});

test("intro lead-ins remain descriptions while summary lead-ins stay deliberately filtered", () => {
  const parsed = parseReadme([
    "# Tool", "", "This package contains three skills:", "", "- A source skill.", "",
    "## Prerequisites", "", "Run the following:", "", "```sh", "install tool", "```",
  ].join("\n"));
  assert.equal(parsed.readmeLead, "This package contains three skills:");
  assert.deepEqual(parsed.contextRequirements, []);
});

test("an intro paragraph stops before an immediately following Markdown list", () => {
  const parsed = parseReadme([
    "# Tool", "", "This package contains three skills:",
    "- A source skill.", "- Another source skill.", "",
    "## Requirements", "", "- PHP 8.2.",
  ].join("\n"));
  assert.equal(parsed.readmeLead, "This package contains three skills:");
  assert.deepEqual(parsed.contextRequirements, ["PHP 8.2."]);
});

test("missing sections do not acquire invented outputs or requirements", () => {
  assert.deepEqual(parseReadme("# Tool\n\nA source description.\n\n## Installation\n\n- Setup command.\n"), {
    useCases: [], expectedOutputs: [], contextRequirements: [], relatedSkills: [], tags: [],
    readmeLead: "A source description.",
  });
  for (const input of [null, undefined, 42, ""]) {
    assert.deepEqual(parseReadme(input), {
      useCases: [], expectedOutputs: [], contextRequirements: [], relatedSkills: [], tags: [], readmeLead: null,
    });
  }
});
