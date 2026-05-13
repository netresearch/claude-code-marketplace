/**
 * Lookup index for related-skill rendering on detail pages.
 * Mirrors skills.js but keyed by slug so templates can resolve
 * a related-skill reference to its display name + category in O(1).
 */
import skillsLoader from "./skills.js";

export default function () {
  const skills = skillsLoader();
  const map = {};
  for (const skill of skills) {
    map[skill.slug] = skill;
  }
  return map;
}
