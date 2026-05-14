/**
 * Search-index payload per locale. Templates under src/<lang>/search/
 * just dump the matching list, no Nunjucks array mutation needed.
 *
 * Shape: `{ en: [...records], de: [...records] }` where each record is
 * { slug, name, desc, category, categorySlug, group, tags, useCases, url }.
 */
import skillsLoader from "./skills.js";

function urlFor(lang, slug, pathPrefix) {
  return `${pathPrefix}${lang}/skills/${slug}/`;
}

export default function () {
  const skills = skillsLoader();
  // `PATH_PREFIX` is honoured by Eleventy's `| url` filter; mirror it here so
  // the JSON the JS fetches matches the live deploy URLs verbatim.
  const pathPrefix = process.env.PATH_PREFIX ?? "/claude-code-marketplace/";

  function build(lang) {
    return skills.map((skill) => ({
      slug: skill.slug,
      name: skill.displayName,
      desc: lang === "de" ? skill.descriptionDe : skill.descriptionEn,
      category: lang === "de" ? skill.categoryLabelDe : skill.categoryLabelEn,
      categorySlug: skill.category,
      group: skill.group,
      tags: skill.tags,
      useCases: skill.useCases,
      url: urlFor(lang, skill.slug, pathPrefix),
    }));
  }

  return {
    en: build("en"),
    de: build("de"),
  };
}
