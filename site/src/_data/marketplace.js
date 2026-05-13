import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const MARKETPLACE_JSON = resolve(__dirname, "../../../.claude-plugin/marketplace.json");

export default function () {
  const raw = readFileSync(MARKETPLACE_JSON, "utf8");
  const data = JSON.parse(raw);

  const skills = data.plugins.map((plugin) => ({
    slug: plugin.name,
    description: plugin.description,
    category: plugin.category,
    repo: plugin.source?.repo ?? null,
    repoUrl: plugin.source?.repo
      ? `https://github.com/${plugin.source.repo}`
      : null,
    installCommand: `/plugin install ${plugin.name}@${data.name}`,
  }));

  const categoryCounts = skills.reduce((acc, skill) => {
    acc[skill.category] = (acc[skill.category] || 0) + 1;
    return acc;
  }, {});

  return {
    name: data.name,
    description: data.description,
    owner: data.owner,
    addCommand: `/plugin marketplace add netresearch/claude-code-marketplace`,
    skills,
    count: skills.length,
    categoryCounts,
  };
}
