// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Netresearch DTT GmbH
import assert from "node:assert/strict";
import test from "node:test";
import { checkCatalogMetadata } from "../scripts/check-catalog-metadata.js";

function completeCatalog() {
  const detail = (slug) => ({
    useCases: ["Ein Projekt gezielt prüfen."],
    expectedOutputs: ["Ein nachvollziehbarer Prüfbericht."],
    contextRequirements: ["Zugriff auf das Projekt."],
    provenance: {
      sourceUrl: `https://github.com/example/${slug}-skill#readme`,
      reviewedAt: "2026-10-25",
      sourceSnapshotSha256: "a".repeat(64),
    },
  });
  return {
    marketplace: { plugins: [
      { name: "alpha", source: { repo: "example/alpha-skill" } },
      { name: "beta", source: { repo: "example/beta-skill" } },
    ] },
    displayNames: { _doc: "Curated labels", alpha: "Alpha", beta: "Beta" },
    descriptionsDe: { _doc: "Deutsche Beschreibungen", alpha: "Prüft ein Projekt.", beta: "Bereitet Ergebnisse vor." },
    detailsDe: { _doc: "German presentation", _provenance: { reviewedAt: "2026-10-25" }, alpha: detail("alpha"), beta: detail("beta") },
    groups: { order: ["engineering"], groups: { engineering: { slugs: ["alpha", "beta"] } } },
    readme: [
      "# Marketplace", "", "## Available Skills", "", "### Engineering", "",
      "| Skill | Repository | Description |", "| --- | --- | --- |",
      "| alpha | [Source](https://github.com/example/alpha-skill) | Checks projects. |",
      "| beta | [Source](https://github.com/example/beta-skill) | Produces results. |", "",
      "Host-side tooling: [composer-agent-skill-plugin](https://github.com/example/installer).", "",
      "## Architecture", "", "| Skill | Repository | Description |", "| --- | --- | --- |",
      "| unrelated-example | Source | An example outside the catalog. |",
    ].join("\n"),
  };
}

test("a complete catalog accepts documentary keys and ignores host tooling prose", () => {
  const data = completeCatalog();
  const before = structuredClone(data);
  assert.deepEqual(checkCatalogMetadata(data), []);
  assert.deepEqual(data, before, "validation must not rewrite source data");
});

test("a missing display-name row fails even though rendering could title-case a slug", () => {
  const data = completeCatalog();
  delete data.displayNames.beta;
  assert.ok(checkCatalogMetadata(data).some(({ path }) => path === "displayNames.beta"));
});

test("missing or blank German descriptions fail instead of permitting an English fallback", () => {
  for (const value of [undefined, "  "]) {
    const data = completeCatalog();
    data.descriptionsDe.beta = value;
    assert.ok(checkCatalogMetadata(data).some(({ path }) => path === "descriptions_de.beta"));
  }
});

test("each catalog entry must occur in exactly one presentation group", () => {
  const duplicate = completeCatalog();
  duplicate.groups.order.push("other");
  duplicate.groups.groups.other = { slugs: ["alpha"] };
  assert.ok(checkCatalogMetadata(duplicate).some(({ code, slug }) => code === "group-membership" && slug === "alpha"));

  const missing = completeCatalog();
  missing.groups.groups.engineering.slugs = ["alpha"];
  assert.ok(checkCatalogMetadata(missing).some(({ code, slug }) => code === "group-membership" && slug === "beta"));
});

test("retired coach membership and stale localized rows are rejected", () => {
  const data = completeCatalog();
  data.groups.groups.engineering.slugs.push("coach");
  data.detailsDe.retired = structuredClone(data.detailsDe.alpha);
  assert.ok(checkCatalogMetadata(data).some(({ code, slug }) => code === "unknown-group-entry" && slug === "coach"));
  assert.ok(checkCatalogMetadata(data).some(({ path }) => path === "details_de.retired"));
});

test("an unordered group cannot hide a catalog entry from the rendered landing", () => {
  const data = completeCatalog();
  data.groups.order = [];
  assert.ok(checkCatalogMetadata(data).some(({ code }) => code === "group-order"));
});

test("a missing German detail row fails independently of a valid short description", () => {
  const data = completeCatalog();
  delete data.detailsDe.beta;
  assert.ok(checkCatalogMetadata(data).some(({ path }) => path === "details_de.beta"));
});

test("German detail sections require nonempty string arrays", () => {
  for (const [field, value] of [["useCases", []], ["expectedOutputs", "A result"], ["contextRequirements", ["  "]]]) {
    const data = completeCatalog();
    data.detailsDe.beta[field] = value;
    assert.ok(checkCatalogMetadata(data).some(({ path }) => path === `details_de.beta.${field}`), field);
  }
});

test("source review provenance rejects invalid dates, hashes and unrelated sources", () => {
  for (const [field, value] of [
    ["reviewedAt", "2026-02-31"],
    ["sourceSnapshotSha256", "not-a-snapshot-hash"],
    ["sourceUrl", "https://github.com/example/beta-skill-malicious#readme"],
    ["sourceUrl", "javascript:alert(1)"],
  ]) {
    const data = completeCatalog();
    data.detailsDe.beta.provenance[field] = value;
    assert.ok(checkCatalogMetadata(data).some(({ path }) => path === `details_de.beta.provenance.${field}`), field);
  }
});

test("a historical snapshot hash stays valid without a freshness lock on fetched READMEs", () => {
  const data = completeCatalog();
  data.detailsDe.beta.provenance.reviewedAt = "2025-01-01";
  data.detailsDe.beta.provenance.sourceSnapshotSha256 = "f".repeat(64);
  assert.deepEqual(checkCatalogMetadata(data), []);
});

test("a duplicated Available Skills row fails even when the catalog set still matches", () => {
  const data = completeCatalog();
  data.readme = data.readme.replace("| beta | [Source]", "| alpha | Source | Duplicate listing. |\n| beta | [Source]");
  assert.ok(checkCatalogMetadata(data).some(({ code, slug }) => code === "readme-membership" && slug === "alpha"));
});

test("unknown README table entries cannot replace a canonical catalog entry", () => {
  const data = completeCatalog();
  data.readme = data.readme.replace("| beta | [Source]", "| coach | [Source]");
  const issues = checkCatalogMetadata(data);
  assert.ok(issues.some(({ code, slug }) => code === "unknown-readme-entry" && slug === "coach"));
  assert.ok(issues.some(({ code, slug }) => code === "readme-membership" && slug === "beta"));
});

test("a fenced table example does not count as a real README listing", () => {
  const data = completeCatalog();
  data.readme = data.readme.replace("### Engineering", [
    "```markdown", "| Skill | Repository | Description |", "| --- | --- | --- |",
    "| example-only | Source | A fenced illustration. |", "```", "", "### Engineering",
  ].join("\n"));
  assert.deepEqual(checkCatalogMetadata(data), []);
});

test("a canonical catalog hidden entirely in an HTML comment fails visible membership", () => {
  const data = completeCatalog();
  data.readme = `<!--\n${data.readme}\n-->`;
  const issues = checkCatalogMetadata(data);
  assert.ok(issues.some(({ code }) => code === "readme-section"));
  assert.deepEqual(issues.filter(({ code }) => code === "readme-membership").map(({ slug }) => slug).sort(), ["alpha", "beta"]);
});

test("commented duplicate and retired tables do not affect the visible catalog", () => {
  const data = completeCatalog();
  data.readme = data.readme.replace("### Engineering", [
    "### Engineering", "", "<!-- Old examples, retained as a comment only.",
    "| Skill | Repository | Description |", "| --- | --- | --- |",
    "| alpha | Source | A hidden duplicate. |", "| coach | Source | A hidden retired entry. |",
    "-->",
  ].join("\n"));
  assert.deepEqual(checkCatalogMetadata(data), []);
});

test("visible README findings retain original line numbers after excluded comments", () => {
  const data = completeCatalog();
  data.readme = data.readme.replace("### Engineering", "### Engineering\n\n<!--\nThree\ncomment lines\n-->");
  data.readme = data.readme.replace("| beta | [Source]", "| coach | [Source]");
  const originalLine = data.readme.split("\n").findIndex((line) => line.startsWith("| coach |")) + 1;
  assert.ok(checkCatalogMetadata(data).some(({ code, path }) => code === "unknown-readme-entry" && path === `README.md:${originalLine}`));
});

test("an illustrative comment opener inside a code fence cannot hide the real catalog", () => {
  const data = completeCatalog();
  data.readme = data.readme.replace("# Marketplace", "# Marketplace\n\n```html\n<!-- an unclosed example comment\n```\n");
  assert.deepEqual(checkCatalogMetadata(data), []);
});
