// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Netresearch DTT GmbH
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
        lead: "A small family of skills whose subject matter is other skills. At the center runs a loop — Harness, Assessment, Retro — and around it sit authoring and host-side tools that feed the loop.",
      },
      de: {
        title: "Skill-Skills",
        lead: "Skills für Projektanweisungen, überprüfbare Checkpoints und die Pflege anderer Skills. Ergänzt durch Werkzeuge für ihre Installation.",
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
      de: { title: "TYPO3-Entwicklung", lead: "Skills für Extensions, deploybare Projekte, Tests und Dokumentation." },
      slugs: [
        "typo3-conformance",
        "typo3-site-conformance",
        "typo3-testing",
        "typo3-docs",
        "typo3-ddev",
        "typo3-extension-upgrade",
        "typo3-project-upgrade",
        "typo3-ckeditor5",
        "typo3-core-contributions",
        "typo3-typoscript-ref",
        "typo3-a11y",
        "typo3-vite",
        "typo3-upgrade-effort-model",
      ],
    },
    orocommerce: {
      en: { title: "OroCommerce", lead: "Entities, datagrids, REST API, workflows, frontend, security." },
      de: { title: "OroCommerce", lead: "Entwicklung, Schnittstellen und Tests für OroCommerce 6.1." },
      slugs: ["orocommerce"],
    },
    "quality-security": {
      en: { title: "Code Quality & Security", lead: "Modernization, audits, supply-chain hardening." },
      de: { title: "Codequalität und Sicherheit", lead: "PHP modernisieren, Änderungen prüfen und Lieferketten absichern." },
      slugs: [
        "php-modernization",
        "php-structured-edit",
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
        "jujutsu-workflow",
      ],
    },
    productivity: {
      en: { title: "Productivity & Integration", lead: "Daily-driver tooling for engineers and teams." },
      de: { title: "Werkzeuge und Zusammenarbeit", lead: "Skills für Daten, Suche, Kommunikation und die tägliche Projektarbeit." },
      slugs: [
        "jira-integration",
        "matrix-communication",
        "cli-tools",
        "context7",
        "data-tools",
        "file-search",
        "german-technical-writing",
        "peer-qa-review",
        "markdown-to-pdf",
      ],
    },
    brand: {
      en: { title: "Brand & visual identity", lead: "Visual conventions for Netresearch artifacts." },
      de: { title: "Netresearch-Gestaltung", lead: "Farben, Typografie und Vorlagen für Beiträge und Materialien von Netresearch." },
      slugs: ["netresearch-branding"],
    },
  },
};
