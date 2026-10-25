// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Netresearch DTT GmbH
import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { runInNewContext } from "node:vm";

const script = readFileSync(new URL("../src/assets/js/enhance.js", import.meta.url), "utf8");
const records = [
  { slug: "typo3-conformance", name: "TYPO3 Conformance", desc: "", category: "development" },
  { slug: "docker-development", name: "Docker Development", desc: "", category: "devops" },
];

// Exercise the shipped script with a minimal DOM boundary and deterministic
// timers. No browser or network is needed during the pre-build compliance gate.
function element(attributes = {}, textContent = "") {
  const handlers = new Map();
  return {
    hidden: Object.hasOwn(attributes, "hidden"), textContent,
    getAttribute: (name) => attributes[name] ?? null,
    hasAttribute: (name) => Object.hasOwn(attributes, name),
    setAttribute(name, value) { attributes[name] = value; },
    removeAttribute(name) { delete attributes[name]; },
    addEventListener(name, handler) { handlers.set(name, handler); },
    fire(name, event = {}) { handlers.get(name)?.(event); },
    querySelector() { return null; },
    querySelectorAll() { return []; },
  };
}

function setup({ deferred = false, clipboardFails = false, storedMode = null, unsupportedCard = false } = {}) {
  let currentTime = 0;
  let nextTimer = 0;
  const timers = new Map();
  const setTimeout = (fn, delay = 0) => {
    timers.set(++nextTimer, { fn, due: currentTime + delay });
    return nextTimer;
  };
  function tick(milliseconds) {
    const until = currentTime + milliseconds;
    for (;;) {
      const next = [...timers].filter(([, timer]) => timer.due <= until)
        .sort((a, b) => a[1].due - b[1].due)[0];
      if (!next) break;
      timers.delete(next[0]);
      currentTime = next[1].due;
      next[1].fn();
    }
    currentTime = until;
  }

  const input = element();
  input.value = "";
  const clear = element({ hidden: "" });
  const status = element();
  const search = element({
    hidden: "", "data-enhance-only": "", "data-index-url": "/index.json",
    "data-no-results": "Keine Treffer", "data-results-template": "{count} Treffer",
    "data-search-error": "Suche nicht verfügbar. Alle Skills bleiben sichtbar.",
  });
  search.querySelector = (selector) => ({
    "[data-search-input]": input, "[data-search-clear]": clear, "[data-search-status]": status,
  })[selector] || null;
  const cards = records.map((record) => {
    const card = element();
    card.querySelector = () => element({ href: `/claude-code-marketplace/en/skills/${record.slug}/` });
    return card;
  });
  const group = element();
  group.querySelectorAll = () => cards.filter((card) => !card.hidden);

  const modes = ["claude-code", "npx", "composer-require", "composer-skills"].map((mode) => {
    const button = element({ "data-install-mode-id": mode, "aria-pressed": String(mode === "claude-code") });
    button.closest = () => button;
    button.querySelector = () => element({}, mode);
    return button;
  });
  const switcher = element({ hidden: "", "data-enhance-only": "", "data-install-mode-announce": "Methode: {label}" });
  switcher.querySelectorAll = (selector) => selector === "[data-install-mode-id]" ? modes : [];
  switcher.querySelector = () => element();
  const body = element({ "data-install-mode": "claude-code" });

  const copyStatus = element();
  const copy = element({
    hidden: "", "data-enhance-only": "", "data-copy-target": "install",
    "data-copied-label": "Kopiert", "data-copy-failed-label": "Kopieren fehlgeschlagen.",
    "data-copy-prompt-label": "Installationsbefehl kopieren:", "aria-label": "Befehl kopieren",
  }, "Kopieren");
  if (unsupportedCard) {
    copy.removeAttribute("data-copy-target");
    copy.setAttribute("data-copy-active-install", "");
  }
  const installs = element();
  installs.querySelector = (selector) => {
    if (selector === ".install--composer-require") return { innerText: "Package installation unavailable" };
    const mode = selector.replace(/^code\.install--/, "");
    return mode !== "composer-require" && selector.startsWith("code.install--")
      ? { innerText: mode === "npx" ? "npx skills add example --skill cli-tools" : "/plugin install cli-tools@netresearch" }
      : null;
  };
  copy.closest = (selector) => selector === ".skill-card__installs" ? installs : copy;
  const document = element();
  document.body = body;
  document.querySelector = (selector) => ({
    "[data-search]": search, "[data-install-mode-switcher]": switcher, "[data-copy-status]": copyStatus,
  })[selector] || null;
  document.querySelectorAll = (selector) => selector === ".group" ? [group]
    : selector === ".skill-card" ? cards : selector.includes("copy-btn") ? [copy]
      : selector === "[data-copy-active-install]" && copy.hasAttribute("data-copy-active-install") ? [copy] : [];
  document.getElementById = () => ({ innerText: " /plugin install typo3-conformance@netresearch " });

  let resolveFetch;
  let rejectFetch;
  const pendingFetch = new Promise((resolve, reject) => { resolveFetch = resolve; rejectFetch = reject; });
  const copied = [];
  const prompts = [];
  const storage = new Map(storedMode ? [["netresearch-marketplace:install-mode", storedMode]] : []);
  runInNewContext(script, {
    document, navigator: { clipboard: { writeText: async (text) => {
      if (clipboardFails) throw new Error("denied");
      copied.push(text);
    } } },
    window: {
      location: { search: "" },
      localStorage: { getItem: (key) => storage.get(key), setItem: (key, value) => storage.set(key, value) },
      prompt: (...args) => prompts.push(args),
    },
    fetch: () => deferred ? pendingFetch : Promise.resolve({ ok: true, json: async () => records }),
    URLSearchParams, setTimeout, clearTimeout: (id) => timers.delete(id), console: { warn() {} },
  });
  return {
    input, clear, status, search, cards, switcher, modes, body, copy, copyStatus, copied, prompts, storage, tick,
    type(query) { input.value = query; input.fire("input"); },
    reset() { input.value = ""; search.fire("reset"); tick(0); },
    clickCopy() { document.fire("click", { target: copy }); },
    releaseIndex() { resolveFetch({ ok: true, json: async () => records }); },
    failIndex() { rejectFetch(new Error("offline")); },
  };
}

async function settle() {
  for (let i = 0; i < 8; i++) await Promise.resolve();
}

test("clearing search while its index loads keeps the full catalog visible", async () => {
  const ui = setup({ deferred: true });
  ui.type("typo3");
  ui.tick(80);
  ui.reset();
  ui.releaseIndex();
  await settle();
  assert.equal(ui.input.value, "");
  assert.deepEqual(ui.cards.map((card) => card.hidden), [false, false]);
  assert.equal(ui.status.textContent, "");
});

test("reset cancels a query that is still waiting for its debounce", async () => {
  const ui = setup();
  ui.type("typo3");
  ui.reset();
  ui.tick(80);
  await settle();
  assert.deepEqual(ui.cards.map((card) => card.hidden), [false, false]);
  assert.equal(ui.status.textContent, "");
});

test("failed search loading announces a localized error and keeps the catalog visible", async () => {
  const ui = setup({ deferred: true });
  ui.type("typo3");
  ui.tick(80);
  ui.failIndex();
  await settle();
  assert.deepEqual(ui.cards.map((card) => card.hidden), [false, false]);
  assert.equal(ui.status.textContent, "Suche nicht verfügbar. Alle Skills bleiben sichtbar.");
});

test("a stored install preference and native button activation update one pressed state", () => {
  const ui = setup({ storedMode: "npx" });
  assert.equal(ui.body.getAttribute("data-install-mode"), "npx");
  assert.deepEqual(ui.modes.map((mode) => mode.getAttribute("aria-pressed")), ["false", "true", "false", "false"]);
  ui.switcher.fire("click", { target: ui.modes[2] });
  assert.equal(ui.body.getAttribute("data-install-mode"), "composer-require");
  assert.deepEqual(ui.modes.map((mode) => mode.getAttribute("aria-pressed")), ["false", "false", "true", "false"]);
  assert.ok(ui.modes.every((mode) => mode.getAttribute("tabindex") === null));
});

test("JS-only controls appear after their handlers have been initialized", () => {
  const ui = setup();
  assert.equal(ui.search.hidden, false);
  assert.equal(ui.switcher.hidden, false);
  assert.equal(ui.copy.hidden, false);
});

test("repeated copies announce success and restore the original visible and accessible labels", async () => {
  const ui = setup();
  ui.clickCopy();
  await settle();
  ui.tick(0);
  assert.equal(ui.copyStatus.textContent, "Kopiert");
  ui.tick(500);
  ui.clickCopy();
  await settle();
  ui.tick(1500);
  assert.deepEqual(ui.copied, ["/plugin install typo3-conformance@netresearch", "/plugin install typo3-conformance@netresearch"]);
  assert.equal(ui.copy.textContent, "Kopieren");
  assert.equal(ui.copy.getAttribute("aria-label"), "Befehl kopieren");
});

test("clipboard rejection provides a localized manual-copy fallback and live feedback", async () => {
  const ui = setup({ clipboardFails: true });
  ui.clickCopy();
  await settle();
  ui.tick(0);
  assert.equal(ui.copyStatus.textContent, "Kopieren fehlgeschlagen.");
  assert.deepEqual(ui.prompts, [["Installationsbefehl kopieren:", "/plugin install typo3-conformance@netresearch"]]);
  assert.equal(ui.copy.getAttribute("aria-label"), "Befehl kopieren");
});

test("unavailable card modes disable copying the placeholder and available modes re-enable real commands", async () => {
  const ui = setup({ unsupportedCard: true });
  ui.switcher.fire("click", { target: ui.modes[2] });
  assert.equal(ui.copy.disabled, true);
  ui.clickCopy();
  await settle();
  assert.deepEqual(ui.copied, []);
  ui.switcher.fire("click", { target: ui.modes[1] });
  assert.equal(ui.copy.disabled, false);
  ui.clickCopy();
  await settle();
  assert.deepEqual(ui.copied, ["npx skills add example --skill cli-tools"]);
});
