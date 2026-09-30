// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Netresearch DTT GmbH
/**
 * Allowlist for link targets taken from fetched README text: http(s), mailto,
 * absolute and relative paths, fragments. Anything else (`javascript:`,
 * `data:`, `vbscript:` and their obfuscated spellings) is rejected, because an
 * allowlist closes that class where a "strip dangerous schemes" filter can be
 * bypassed with tabs or zero-width characters.
 */
export const SAFE_URL_PREFIX = /^(?:https?:\/\/|mailto:|\/|#|\.{0,2}\/|[A-Za-z0-9_-]+(?:\/|#|$))/;

export function isSafeHref(href) {
  return typeof href === "string" && SAFE_URL_PREFIX.test(href);
}
