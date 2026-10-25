// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Netresearch DTT GmbH
export default {
  layout: "layouts/base.njk",
  permalink: "/404.html",
  eleventyExcludeFromCollections: true,
  lang: "en",
  ogLocale: "en_US",
  robots: "noindex",
  hreflangAlternate: { lang: "de", url: "/de/404.html", ogLocale: "de_DE" },
  xDefaultUrl: "/404.html",
  eleventyComputed: {
    t: (data) => data.i18n.en,
    title: (data) => data.i18n.en.notFound.title,
    description: (data) => data.i18n.en.notFound.description,
  },
};
