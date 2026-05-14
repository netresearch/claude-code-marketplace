/**
 * Install-method config. Drives the global tablist on the landing,
 * the per-card command swap, and the per-skill detail-page section.
 *
 * Each method exposes a `command(skill, marketplace)` builder so adding
 * or renaming a method is one place. Order = display order in the
 * tablist and on the detail page.
 */
export default {
  default: "claude-code",
  methods: [
    {
      id: "claude-code",
      labels: {
        en: { tab: "Claude Code", subtitle: "via this marketplace" },
        de: { tab: "Claude Code", subtitle: "über diesen Marketplace" },
      },
      command(skill, marketplace) {
        return `/plugin install ${skill.slug}@${marketplace.name}`;
      },
    },
    {
      id: "npx",
      labels: {
        en: { tab: "npx", subtitle: "any Agent Skills CLI" },
        de: { tab: "npx", subtitle: "beliebige Agent-Skills-CLI" },
      },
      command(skill) {
        if (!skill.repo) return null;
        return `npx skills add https://github.com/${skill.repo} --skill ${skill.slug}`;
      },
    },
    {
      id: "composer-require",
      labels: {
        en: { tab: "composer require", subtitle: "PHP project, as a package" },
        de: { tab: "composer require", subtitle: "PHP-Projekt, als Paket" },
      },
      command(skill) {
        if (!skill.repo) return null;
        return `composer require ${skill.repo}`;
      },
    },
    {
      id: "composer-skills",
      labels: {
        en: { tab: "composer skills:add", subtitle: "PHP project, direct source" },
        de: { tab: "composer skills:add", subtitle: "PHP-Projekt, direkte Quelle" },
      },
      command(skill) {
        if (!skill.repo) return null;
        return `composer skills:add github:${skill.repo}`;
      },
    },
  ],
};
