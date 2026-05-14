/**
 * Marketplace-level metadata for landings (count, descriptions, owner,
 * add-marketplace command, category histogram).
 *
 * Per-skill data lives in `_data/skills.js`. Templates that need full
 * skill records (including `installCommands`) should iterate over the
 * `skills` collection from there, not `marketplace.skills`.
 */
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const MARKETPLACE_JSON = resolve(__dirname, "../../../.claude-plugin/marketplace.json");

export default function () {
  const data = JSON.parse(readFileSync(MARKETPLACE_JSON, "utf8"));

  const categoryCounts = data.plugins.reduce((acc, plugin) => {
    acc[plugin.category] = (acc[plugin.category] || 0) + 1;
    return acc;
  }, {});

  return {
    name: data.name,
    description: data.description,
    owner: data.owner,
    addCommand: `/plugin marketplace add netresearch/claude-code-marketplace`,
    count: data.plugins.length,
    categoryCounts,
  };
}
