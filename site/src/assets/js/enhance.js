// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Netresearch DTT GmbH
/*
 * Progressive enhancement — landing functions without this script.
 * Total budget: under 5 KB minified. No frameworks. No third-party imports.
 *
 * Features:
 *   - Install-method buttons on landings (claude-code | npx | composer-require
 *     | composer-skills); persists in localStorage; CSS show/hides per
 *     body[data-install-mode]; native buttons expose their pressed state.
 *   - Copy-to-clipboard for install commands (with localized "Copied/Kopiert"
 *     flash; supports both explicit data-copy-target and dynamic
 *     data-copy-active-install resolution against the active mode).
 *   - Client-side skill search (lazy-loaded JSON index, in-place card filtering).
 */
(function () {
  "use strict";

  function reveal(control) {
    if (control && control.hasAttribute("data-enhance-only")) control.hidden = false;
  }

  function updateCardCopies(mode) {
    document.querySelectorAll("[data-copy-active-install]").forEach(function (btn) {
      var container = btn.closest(".skill-card__installs");
      btn.disabled = !container || !container.querySelector("code.install--" + mode);
    });
  }

  // ----- install-method preference --------------------------------------
  var installSwitcher = document.querySelector("[data-install-mode-switcher]");
  if (installSwitcher) {
    var installTabs = Array.prototype.slice.call(
      installSwitcher.querySelectorAll("[data-install-mode-id]")
    );
    var installStatusEl = installSwitcher.querySelector("[data-install-mode-status]");
    var STORAGE_KEY = "netresearch-marketplace:install-mode";

    function setMode(modeId) {
      // Validate first — never half-apply the change. If the stored mode is
      // unknown (e.g. user came from an older deploy with different method
      // ids), bail out and keep the markup-defined default.
      var match = null;
      for (var i = 0; i < installTabs.length; i++) {
        if (installTabs[i].getAttribute("data-install-mode-id") === modeId) {
          match = installTabs[i];
          break;
        }
      }
      if (!match) return false;

      installTabs.forEach(function (tab) {
        var isActive = tab === match;
        tab.setAttribute("aria-pressed", isActive ? "true" : "false");
      });
      if (installStatusEl) {
        var template = installSwitcher.getAttribute("data-install-mode-announce") || "";
        var label = (match.querySelector(".install-mode__tab-label") || {}).textContent || modeId;
        installStatusEl.textContent = template ? template.replace("{label}", label) : "";
      }
      document.body.setAttribute("data-install-mode", modeId);
      updateCardCopies(modeId);
      try { window.localStorage.setItem(STORAGE_KEY, modeId); } catch (_) {}
      return true;
    }

    // Restore from storage if present and known.
    try {
      var stored = window.localStorage.getItem(STORAGE_KEY);
      if (stored) setMode(stored);
    } catch (_) {}

    installSwitcher.addEventListener("click", function (event) {
      var tab = event.target.closest("[data-install-mode-id]");
      if (!tab) return;
      setMode(tab.getAttribute("data-install-mode-id"));
    });

    reveal(installSwitcher);
  }

  // ----- search ---------------------------------------------------------
  var searchForm = document.querySelector("[data-search]");
  var input = searchForm && searchForm.querySelector("[data-search-input]");
  var indexUrl = searchForm && searchForm.getAttribute("data-index-url");

  // Bail out if anything the search module needs is missing — partial markup
  // shouldn't bring down the rest of enhance.js (clipboard etc.).
  if (searchForm && input && indexUrl) {
    var clearBtn = searchForm.querySelector("[data-search-clear]");
    var statusEl = searchForm.querySelector("[data-search-status]");
    var noResultsMsg = searchForm.getAttribute("data-no-results") || "";
    var resultsTpl = searchForm.getAttribute("data-results-template") || "{count}";
    var searchErrorMsg = searchForm.getAttribute("data-search-error") || "";

    var indexCache = null;
    var indexPending = null;
    var searchRevision = 0;

    function loadIndex() {
      if (indexCache) return Promise.resolve(indexCache);
      if (indexPending) return indexPending;
      indexPending = fetch(indexUrl, { credentials: "same-origin" })
        .then(function (r) {
          if (!r.ok) throw new Error("index fetch " + r.status);
          return r.json();
        })
        .then(function (data) {
          if (!Array.isArray(data)) throw new Error("invalid search index");
          indexCache = data;
          indexPending = null;
          return data;
        })
        .catch(function () {
          indexPending = null;
          return null;
        });
      return indexPending;
    }

    function tokenize(s) {
      return String(s || "").toLowerCase().split(/\s+/).filter(Boolean);
    }

    function recordMatches(record, tokens) {
      var hay = (
        record.slug + " " +
        record.name + " " +
        record.desc + " " +
        record.category + " " +
        (record.group || "") + " " +
        (record.tags || []).join(" ") + " " +
        (record.useCases || []).join(" ")
      ).toLowerCase();
      for (var i = 0; i < tokens.length; i++) {
        if (hay.indexOf(tokens[i]) === -1) return false;
      }
      return true;
    }

    function applyFilter(query) {
      var revision = ++searchRevision;
      var groups = document.querySelectorAll(".group");
      var cards = document.querySelectorAll(".skill-card");

      function showAll() {
        for (var c = 0; c < cards.length; c++) cards[c].hidden = false;
        for (var g = 0; g < groups.length; g++) groups[g].hidden = false;
      }

      if (!query) {
        showAll();
        if (statusEl) statusEl.textContent = "";
        if (clearBtn) clearBtn.hidden = true;
        return;
      }

      if (clearBtn) clearBtn.hidden = false;
      if (!statusEl) return;

      loadIndex().then(function (records) {
        if (revision !== searchRevision) return;
        if (!records) {
          showAll();
          statusEl.textContent = searchErrorMsg;
          return;
        }
        var tokens = tokenize(query);
        var matchedSlugs = {};
        var matchCount = 0;
        for (var i = 0; i < records.length; i++) {
          if (recordMatches(records[i], tokens)) {
            matchedSlugs[records[i].slug] = true;
            matchCount++;
          }
        }

        for (var c = 0; c < cards.length; c++) {
          var titleLink = cards[c].querySelector(".skill-card__title a");
          var slug = "";
          if (titleLink) {
            var m = titleLink.getAttribute("href").match(/\/skills\/([^/]+)\//);
            slug = m ? m[1] : "";
          }
          cards[c].hidden = !matchedSlugs[slug];
        }

        for (var g = 0; g < groups.length; g++) {
          var visible = groups[g].querySelectorAll(".skill-card:not([hidden])").length;
          groups[g].hidden = visible === 0;
        }

        statusEl.textContent = matchCount === 0
          ? noResultsMsg
          : resultsTpl.replace("{count}", String(matchCount));
      });
    }

    var debounceTimer = null;
    input.addEventListener("input", function () {
      searchRevision++;
      var query = input.value.trim();
      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(function () {
        applyFilter(query);
      }, 80);
    });

    searchForm.addEventListener("reset", function () {
      searchRevision++;
      clearTimeout(debounceTimer);
      setTimeout(function () { applyFilter(input.value.trim()); }, 0);
    });
    reveal(searchForm);

    // Prefill from ?q=... — supports the SearchAction urlTemplate
    // (`/<lang>/?q={search_term_string}#skills`) and any shared link.
    var initialQuery = new URLSearchParams(window.location.search).get("q");
    if (initialQuery) {
      input.value = initialQuery;
      applyFilter(initialQuery.trim());
    }
  }

  // ----- clipboard ------------------------------------------------------
  var copyStatusEl = document.querySelector("[data-copy-status]");
  var copyStates = new WeakMap();

  function announceCopy(message) {
    if (!copyStatusEl) return;
    copyStatusEl.textContent = "";
    setTimeout(function () { copyStatusEl.textContent = message; }, 0);
  }

  document.addEventListener("click", function (event) {
    var btn = event.target.closest(".copy-btn");
    if (!btn || btn.disabled) return;

    var target = null;
    var targetId = btn.getAttribute("data-copy-target");
    if (targetId) {
      target = document.getElementById(targetId);
    } else if (btn.hasAttribute("data-copy-active-install")) {
      // Skill-card button — copy whichever install command matches the active
      // body[data-install-mode]. CSS hides the others; we look them up by class.
      var mode = document.body.getAttribute("data-install-mode") || "claude-code";
      var container = btn.closest(".skill-card__installs");
      if (container) target = container.querySelector("code.install--" + mode);
    }
    if (!target) return;

    var text = target.innerText.trim();

    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(
        function () { flashCopied(btn); },
        function () { fallbackPrompt(text, btn); }
      );
    } else {
      fallbackPrompt(text, btn);
    }
  });
  updateCardCopies(document.body.getAttribute("data-install-mode") || "claude-code");
  document.querySelectorAll(".copy-btn[data-enhance-only]").forEach(reveal);

  function flashCopied(btn) {
    var label = btn.querySelector(".copy-btn__label") || btn;
    var state = copyStates.get(btn) || { original: label.textContent, timer: null };
    clearTimeout(state.timer);
    var copiedText = btn.getAttribute("data-copied-label") || state.original;
    label.textContent = copiedText;
    btn.setAttribute("data-state", "copied");
    announceCopy(copiedText);
    state.timer = setTimeout(function () {
      label.textContent = state.original;
      btn.removeAttribute("data-state");
    }, 1500);
    copyStates.set(btn, state);
  }

  function fallbackPrompt(text, btn) {
    announceCopy(btn.getAttribute("data-copy-failed-label") || "");
    window.prompt(btn.getAttribute("data-copy-prompt-label") || "", text);
  }
})();
