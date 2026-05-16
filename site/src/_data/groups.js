/**
 * Presentation groups for the landing page.
 *
 * These mirror the thematic headings used in README.md (orthogonal to the
 * canonical category enum from AGENTS.md — categories serve filter + SEO,
 * groups serve story-driven discovery). Slug membership stays declarative
 * here so the landing renders deterministically regardless of marketplace.json
 * ordering.
 *
 * When new skills are added to the marketplace, add their slug to the most
 * appropriate group. Skills missing from any group fall into "uncategorized"
 * at the bottom of the landing.
 */
export default {
  order: [
    "skill-skills",
    "typo3",
    "orocommerce",
    "quality-security",
    "devops",
    "productivity",
    "brand",
  ],
  groups: {
    "skill-skills": {
      en: {
        title: "Skill-skills",
        lead: "A small family of skills whose subject matter is other skills. At the centre runs a loop — Harness, Assessment, Retro — and around it sit authoring and host-side tools that feed the loop.",
      },
      de: {
        title: "Skill-Skills",
        lead: "Eine kleine Familie von Skills, deren Gegenstand andere Skills sind. Im Zentrum läuft eine Schleife — Harness, Assessment, Retro — drumherum stehen Autoren- und Host-seitige Werkzeuge, die in die Schleife einspeisen.",
      },
      slugs: [
        "agent-harness",
        "automated-assessment",
        "retro",
        "agent-rules",
        "skill-repo",
      ],
    },
    typo3: {
      en: { title: "TYPO3 Development", lead: "Stack-aware skills for TYPO3 extensions and projects." },
      de: { title: "TYPO3-Entwicklung", lead: "Stack-spezifische Skills für TYPO3-Extensions und -Projekte." },
      slugs: [
        "typo3-conformance",
        "typo3-testing",
        "typo3-docs",
        "typo3-ddev",
        "typo3-extension-upgrade",
        "typo3-project-upgrade",
        "typo3-ckeditor5",
        "typo3-core-contributions",
        "typo3-typoscript-ref",
        "typo3-a11y",
        "typo3-frontend-patterns",
        "typo3-vite",
        "typo3-upgrade-effort-model",
      ],
    },
    orocommerce: {
      en: { title: "OroCommerce", lead: "Entities, datagrids, REST API, workflows, frontend, security." },
      de: { title: "OroCommerce", lead: "Entities, Datagrids, REST-API, Workflows, Frontend, Security." },
      slugs: ["orocommerce"],
    },
    "quality-security": {
      en: { title: "Code Quality & Security", lead: "Modernization, audits, supply-chain hardening." },
      de: { title: "Code-Qualität & Sicherheit", lead: "Modernisierung, Audits, Supply-Chain-Härtung." },
      slugs: [
        "php-modernization",
        "security-audit",
        "enterprise-readiness",
      ],
    },
    devops: {
      en: { title: "DevOps & Infrastructure", lead: "Build, ship, automate." },
      de: { title: "DevOps & Infrastruktur", lead: "Bauen, ausliefern, automatisieren." },
      slugs: [
        "docker-development",
        "concourse-ci",
        "go-development",
        "git-workflow",
        "github-project",
        "github-release",
      ],
    },
    productivity: {
      en: { title: "Productivity & Integration", lead: "Daily-driver tooling for engineers and teams." },
      de: { title: "Produktivität & Integration", lead: "Alltags-Werkzeuge für Engineering-Teams." },
      slugs: [
        "jira-integration",
        "matrix-communication",
        "cli-tools",
        "context7",
        "data-tools",
        "file-search",
        "pagerangers-seo",
        "coach",
        "german-technical-writing",
        "peer-qa-review",
        "markdown-to-pdf",
      ],
    },
    brand: {
      en: { title: "Brand & visual identity", lead: "Visual conventions for Netresearch artifacts." },
      de: { title: "Brand & visuelle Identität", lead: "Visuelle Konventionen für Netresearch-Artefakte." },
      slugs: ["netresearch-branding"],
    },
  },
};
