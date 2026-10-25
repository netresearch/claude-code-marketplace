// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Netresearch DTT GmbH
export default {
  layout: "layouts/base.njk",
  permalink: "/404.html",
  eleventyExcludeFromCollections: true,
  lang: "en",
  ogLocale: "en_US",
  title: "Page not found — Netresearch Skills Marketplace",
  description: "This address does not exist. Browse the skills catalog in English or German.",
  robots: "noindex",
  hreflangAlternate: { lang: "de", url: "/de/404.html", ogLocale: "de_DE" },
  xDefaultUrl: "/404.html",
  eleventyComputed: { t: (data) => data.i18n.en },
};
