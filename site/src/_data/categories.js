/**
 * Canonical category enum per AGENTS.md §Canonical categories.
 * Mirrors the 7 values enforced by scripts/validate.sh.
 *
 * Display labels are surface-level only; never invent or rename categories.
 */
export default {
  enum: [
    "development",
    "devops",
    "security",
    "design",
    "workflow",
    "productivity",
    "document",
  ],
  labels: {
    en: {
      development: "Development",
      devops: "DevOps & Infrastructure",
      security: "Security",
      design: "Design",
      workflow: "Workflow",
      productivity: "Productivity",
      document: "Documentation",
    },
    de: {
      development: "Entwicklung",
      devops: "DevOps & Infrastruktur",
      security: "Sicherheit",
      design: "Design",
      workflow: "Workflow",
      productivity: "Produktivität",
      document: "Dokumentation",
    },
  },
};
