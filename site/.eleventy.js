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

  // Render an ISO timestamp as YYYY-MM-DD. Used for skill-release dates.
  eleventyConfig.addFilter("isoDate", (input) => {
    if (!input || typeof input !== "string") return "";
    const m = input.match(/^(\d{4}-\d{2}-\d{2})/);
    return m ? m[1] : "";
  });

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
   * not handled — these are short bullet items, not full documents.
   *
   * Two safety properties:
   *
   *   1. Input is HTML-escaped first so untrusted README content can't inject
   *      tags. The output is then re-marked safe by `| safe` at the call site.
   *
   *   2. Code spans are extracted with a sentinel before any other inline
   *      transformation runs, so `**bold**` inside `` `code` `` survives
   *      verbatim and the surrounding bold/italic regexes don't see them.
   *
   *   3. Link hrefs go through an allowlist (http/https/mailto/relative), not
   *      a "strip dangerous schemes" filter — `replace(/javascript:/, "")`
   *      is trivially bypassed by `java\tscript:` or zero-width chars, an
   *      allowlist closes that class entirely.
   */
  const SAFE_URL_PREFIX = /^(?:https?:\/\/|mailto:|\/|#|\.{0,2}\/|[A-Za-z0-9_-]+(?:\/|#|$))/;

  function isSafeHref(href) {
    return SAFE_URL_PREFIX.test(href);
  }

  function escapeHtml(s) {
    return s
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  eleventyConfig.addFilter("inlineMarkdown", (input) => {
    if (!input || typeof input !== "string") return "";

    let s = escapeHtml(input);

    // Stash code-span contents behind sentinels so later regexes can't reach
    // them. Sentinel uses control chars that escapeHtml has already removed
    // from the input, so collisions are impossible.
    const codeStash = [];
    s = s.replace(/`([^`\n]+)`/g, (_, code) => {
      codeStash.push(code);
      return `CODE${codeStash.length - 1}`;
    });

    // [text](href) — href allowlisted; reject everything else by emitting
    // plain text.
    s = s.replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, (_, text, href) => {
      if (!isSafeHref(href)) return `[${text}](${href})`;
      return `<a href="${href}" rel="noopener">${text}</a>`;
    });

    s = s.replace(/\*\*([^*]+?)\*\*/g, "<strong>$1</strong>");
    s = s.replace(/__([^_]+?)__/g, "<strong>$1</strong>");

    // *italic* / _italic_ — only when not adjacent to word characters
    // (so file_names_like_this stay intact).
    s = s.replace(/(^|[^*\w])\*([^*\n]+?)\*(?!\w)/g, "$1<em>$2</em>");
    s = s.replace(/(^|[^_\w])_([^_\n]+?)_(?!\w)/g, "$1<em>$2</em>");

    // Restore stashed code spans, escaping the original content one more time
    // because the input was unescaped between the backticks.
    s = s.replace(/CODE(\d+)/g, (_, idx) => `<code>${codeStash[Number(idx)]}</code>`);

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
