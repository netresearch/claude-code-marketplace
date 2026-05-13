/**
 * Resolve a skill slug to its human-readable display name.
 *
 * Curated names live in _data/displayNames.json (TYPO3 DDEV, OroCommerce,
 * GitHub Project, …). Unknown slugs fall back to a split-and-capitalize
 * fallback so newly-added marketplace entries don't crash the build before
 * an entry is curated.
 *
 * Imported by both `_data/skills.js` (detail pages) and `_data/marketplace.js`
 * (landing cards) so the same name is used everywhere.
 *
 * The path lives under `_data/_helpers/` (leading underscore) so Eleventy
 * doesn't treat it as a data source itself.
 */
import displayNames from "../displayNames.json" with { type: "json" };

export function displayName(slug) {
  return (
    displayNames[slug] ||
    slug
      .split("-")
      .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
      .join(" ")
  );
}
