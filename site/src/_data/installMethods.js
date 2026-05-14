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
      // Claude Code's `/plugin install` is the marketplace's native flow —
      // already explained in the hero. No extra hint needed.
      hint: null,
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
      hint: {
        en: {
          text: "Universal Agent Skills CLI from",
          linkText: "skills.sh",
          linkUrl: "https://skills.sh",
          suffix: "— works across Claude Code, Cursor, GitHub Copilot, Codex, Gemini CLI and 30+ more agents.",
        },
        de: {
          text: "Universelle Agent-Skills-CLI von",
          linkText: "skills.sh",
          linkUrl: "https://skills.sh",
          suffix: "— funktioniert in Claude Code, Cursor, GitHub Copilot, Codex, Gemini CLI und 30+ weiteren Agents.",
        },
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
      hint: {
        en: {
          text: "Requires",
          linkText: "netresearch/composer-agent-skill-plugin",
          linkUrl: "https://github.com/netresearch/composer-agent-skill-plugin",
          suffix: "— resolves Agent Skills as Composer dependencies in PHP projects, auto-discovers skills, generates AGENTS.md.",
        },
        de: {
          text: "Setzt",
          linkText: "netresearch/composer-agent-skill-plugin",
          linkUrl: "https://github.com/netresearch/composer-agent-skill-plugin",
          suffix: "voraus — bindet Agent Skills als Composer-Dependencies in PHP-Projekte ein, erkennt Skills automatisch, generiert AGENTS.md.",
        },
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
      hint: {
        en: {
          text: "Provided by",
          linkText: "netresearch/composer-agent-skill-plugin",
          linkUrl: "https://github.com/netresearch/composer-agent-skill-plugin",
          suffix: "— pins skill repos directly without going through Packagist, locks them in `composer.skills.lock`.",
        },
        de: {
          text: "Kommt aus",
          linkText: "netresearch/composer-agent-skill-plugin",
          linkUrl: "https://github.com/netresearch/composer-agent-skill-plugin",
          suffix: "— pinnt Skill-Repos direkt ohne Packagist-Veröffentlichung, persistiert in `composer.skills.lock`.",
        },
      },
      command(skill) {
        if (!skill.repo) return null;
        return `composer skills:add github:${skill.repo}`;
      },
    },
  ],
};
