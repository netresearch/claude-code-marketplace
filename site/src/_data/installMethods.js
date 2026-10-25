// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Netresearch DTT GmbH
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
      hint: {
        en: {
          prerequisite: "First add the marketplace once in Claude Code: `/plugin marketplace add netresearch/claude-code-marketplace`.",
          text: "Then install the selected plugin. For setup and installation scopes, see",
          linkText: "Claude Code plugin setup",
          linkUrl: "https://code.claude.com/docs/en/discover-plugins#add-a-marketplace",
          suffix: "A plugin can include several skills and additional components.",
        },
        de: {
          prerequisite: "Zuerst den Marketplace einmal in Claude Code hinzufügen: `/plugin marketplace add netresearch/claude-code-marketplace`.",
          text: "Danach das gewünschte Plugin installieren. Einrichtung und Geltungsbereich beschreibt die",
          linkText: "Claude-Code-Anleitung",
          linkUrl: "https://code.claude.com/docs/en/discover-plugins#add-a-marketplace",
          suffix: "Ein Plugin kann mehrere Skills und zusätzliche Bestandteile enthalten.",
        },
      },
      command(skill, marketplace) {
        return `/plugin install ${skill.slug}@${marketplace.name}`;
      },
    },
    {
      id: "npx",
      labels: {
        en: { tab: "npx", subtitle: "interactive skill selection" },
        de: { tab: "npx", subtitle: "Skills gezielt auswählen" },
      },
      hint: {
        en: {
          prerequisite: "Requires Node.js 22.20+. Run from the target project, then choose the source skills and agents in the installer.",
          text: "Uses the skills CLI from",
          linkText: "skills.sh",
          linkUrl: "https://skills.sh",
          suffix: "Installs skill instructions. Extra plugin hooks, commands and external runtime tools are not installed by this route.",
        },
        de: {
          prerequisite: "Benötigt Node.js 22.20+. Im Zielprojekt ausführen und anschließend Skills und Agents im Installer auswählen.",
          text: "Verwendet den skills-Installer von",
          linkText: "skills.sh",
          linkUrl: "https://skills.sh",
          suffix: "Installiert Skill-Anweisungen. Zusätzliche Plugin-Hooks, Befehle und externe Laufzeitwerkzeuge werden damit nicht eingerichtet.",
        },
      },
      command(skill) {
        if (!skill.repo) return null;
        return `npx skills add https://github.com/${skill.repo}`;
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
          prerequisite: "Allow the Composer skill installer to activate and approve skill registration when prompted.",
          text: "Requires",
          linkText: "netresearch/composer-agent-skill-plugin",
          linkUrl: "https://github.com/netresearch/composer-agent-skill-plugin",
          suffix: "Discovers trusted skill packages and registers their instructions in AGENTS.md. Runtime tools may need separate setup.",
        },
        de: {
          prerequisite: "Den Composer-Skill-Installer aktivieren und die Skill-Einbindung auf Nachfrage freigeben.",
          text: "Setzt",
          linkText: "netresearch/composer-agent-skill-plugin",
          linkUrl: "https://github.com/netresearch/composer-agent-skill-plugin",
          suffix: "voraus. Erkennt freigegebene Skill-Pakete und trägt ihre Anweisungen in AGENTS.md ein. Laufzeitwerkzeuge können eine eigene Einrichtung benötigen.",
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
          prerequisite: "Install and activate netresearch/composer-agent-skill-plugin first; approve the selected source's skill registration.",
          text: "Provided by",
          linkText: "netresearch/composer-agent-skill-plugin",
          linkUrl: "https://github.com/netresearch/composer-agent-skill-plugin",
          suffix: "Pins source repositories without a Packagist package and records them in `composer.skills.lock`. Runtime dependencies remain separate.",
        },
        de: {
          prerequisite: "Zuerst netresearch/composer-agent-skill-plugin installieren und aktivieren; die Skill-Einbindung der gewählten Quelle freigeben.",
          text: "Wird bereitgestellt von",
          linkText: "netresearch/composer-agent-skill-plugin",
          linkUrl: "https://github.com/netresearch/composer-agent-skill-plugin",
          suffix: "Bezieht Quell-Repositories ohne Packagist-Paket und hält sie in composer.skills.lock fest. Laufzeitabhängigkeiten werden getrennt eingerichtet.",
        },
      },
      command(skill) {
        if (!skill.repo) return null;
        return `composer skills:add ${skill.repo}`;
      },
    },
  ],
};
