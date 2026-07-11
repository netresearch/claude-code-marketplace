/**
 * Directory data for all /en/ pages.
 * Aliases the EN locale strings + category labels so templates don't
 * have to spell out i18n.en.* on every reference.
 */
export default {
  lang: "en",
  ogLocale: "en_US",
  hreflangAlternate: {
    lang: "de",
    url: "/de/",
    ogLocale: "de_DE",
  },
  xDefaultUrl: "/en/",
  eleventyComputed: {
    t: (data) => data.i18n.en,
    categoryLabels: (data) => data.categories.labels.en,
    valueTypeLabels: (data) => data.valueTypes.labels.en,
  },
};
