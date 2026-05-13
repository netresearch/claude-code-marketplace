/**
 * Eleventy config for the Netresearch Marketplace Pages site.
 *
 * Drives: EN + DE landings under /en/ and /de/, paginated skill detail pages
 * at /<lang>/skills/<slug>/, sitemap.xml + robots.txt + root redirect,
 * passthrough of /assets/ (css, js, og images). Pre-build data comes from
 * scripts/fetch-readmes.js (cached in cache/skills-readme/) + the static
 * marketplace.json catalog.
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

  /**
   * Inline-markdown filter: converts a string with markdown inline syntax
   * (links, bold, italic, code) into safe HTML. Block syntax is intentionally
   * not handled — these are short bullet items, not full documents. Input is
   * always HTML-escaped first so untrusted README content can't inject tags.
   */
  eleventyConfig.addFilter("inlineMarkdown", (input) => {
    if (!input || typeof input !== "string") return "";
    let s = input
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");

    // Inline code first so the runes inside aren't interpreted further.
    s = s.replace(/`([^`]+)`/g, (_, code) => `<code>${code}</code>`);

    // [text](href) — href can be any non-paren run; we already escaped <>"'&.
    s = s.replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, (_, text, href) => {
      const safeHref = href.replace(/javascript:/gi, "");
      return `<a href="${safeHref}" rel="noopener">${text}</a>`;
    });

    // **bold** then __bold__ — the lazy quantifier prevents runaway matches.
    s = s.replace(/\*\*([^*]+?)\*\*/g, "<strong>$1</strong>");
    s = s.replace(/__([^_]+?)__/g, "<strong>$1</strong>");

    // *italic* / _italic_ — only when not adjacent to word characters
    // (so file_names_like_this stay intact).
    s = s.replace(/(^|[^*\w])\*([^*\n]+?)\*(?!\w)/g, "$1<em>$2</em>");
    s = s.replace(/(^|[^_\w])_([^_\n]+?)_(?!\w)/g, "$1<em>$2</em>");

    return s;
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
    // Project Pages deploy lives at https://netresearch.github.io/claude-code-marketplace/
    // pathPrefix tells the `| url` filter to prepend this to every root-relative path.
    // Override at build time with PATH_PREFIX env var when serving from a different mount
    // (e.g. for local preview at root).
    pathPrefix: process.env.PATH_PREFIX ?? "/claude-code-marketplace/",
  };
}
