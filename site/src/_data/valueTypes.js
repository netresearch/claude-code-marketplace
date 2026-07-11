/**
 * Canonical value_type enum per AGENTS.md §Value type (optional).
 * Mirrors the 5 values enforced by scripts/validate.sh. Maps to the A1
 * six-category value rubric (skill-repo-skill#143) — "guardrail" covers
 * both inference suppression and anti-rationalization guards.
 *
 * The field is optional: skills without a value_type simply don't render
 * this facet.
 */
export default {
  enum: [
    "automation-script",
    "org-convention",
    "version-facts",
    "failure-patterns",
    "guardrail",
  ],
  labels: {
    en: {
      "automation-script": "Automation script",
      "org-convention": "Org convention",
      "version-facts": "Version facts",
      "failure-patterns": "Failure patterns",
      guardrail: "Guardrail",
    },
    de: {
      "automation-script": "Automatisierungsskript",
      "org-convention": "Organisationskonvention",
      "version-facts": "Versionsfakten",
      "failure-patterns": "Fehlermuster",
      guardrail: "Guardrail",
    },
  },
};
