/**
 * Eleventy config for the Netresearch Marketplace Pages site.
 *
 * Scope of Phase 2a (Foundation): smoke-test rendering only.
 * i18n permalinks, README fetching, detail pages, sitemaps land in later sub-phases (see PLAN.md).
 */
export default function (eleventyConfig) {
  eleventyConfig.addPassthroughCopy({ "src/assets": "assets" });

  eleventyConfig.addFilter("titleCase", (slug) =>
    String(slug)
      .split("-")
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
      .join(" ")
  );

  eleventyConfig.addFilter("skillsInGroup", (skills, slugs) => {
    const order = new Map(slugs.map((slug, i) => [slug, i]));
    return skills
      .filter((skill) => order.has(skill.slug))
      .sort((a, b) => order.get(a.slug) - order.get(b.slug));
  });

  eleventyConfig.addFilter("skillsNotInAnyGroup", (skills, groups) => {
    const known = new Set(
      Object.values(groups.groups).flatMap((g) => g.slugs)
    );
    return skills.filter((skill) => !known.has(skill.slug));
  });

  return {
    dir: {
      input: "src",
      output: "_site",
      includes: "_includes",
      data: "_data",
    },
    templateFormats: ["njk", "md", "html"],
    markdownTemplateEngine: "njk",
    htmlTemplateEngine: "njk",
  };
}
