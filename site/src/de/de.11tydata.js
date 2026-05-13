export default {
  lang: "de",
  ogLocale: "de_DE",
  hreflangAlternate: {
    lang: "en",
    url: "/en/",
    ogLocale: "en_US",
  },
  xDefaultUrl: "/en/",
  eleventyComputed: {
    t: (data) => data.i18n.de,
    categoryLabels: (data) => data.categories.labels.de,
  },
};
