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
