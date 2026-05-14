/*
 * Progressive enhancement — landing functions without this script.
 * Total budget: under 5 KB minified. No frameworks. No third-party imports.
 *
 * Features:
 *   - Install-method tablist on landings (claude-code | npx | composer-require
 *     | composer-skills); persists in localStorage; CSS show/hides per
 *     body[data-install-mode]; ARIA tablist with arrow-key navigation.
 *   - Copy-to-clipboard for install commands (with localized "Copied/Kopiert"
 *     flash; supports both explicit data-copy-target and dynamic
 *     data-copy-active-install resolution against the active mode).
 *   - Client-side skill search (lazy-loaded JSON index, in-place card filtering).
 */
(function () {
  "use strict";

  // ----- install-method tablist -----------------------------------------
  var installSwitcher = document.querySelector("[data-install-mode-switcher]");
  if (installSwitcher) {
    var tabs = Array.prototype.slice.call(
      installSwitcher.querySelectorAll('[role="tab"]')
    );
    var statusEl = installSwitcher.querySelector("[data-install-mode-status]");
    var STORAGE_KEY = "netresearch-marketplace:install-mode";

    function setMode(modeId, options) {
      options = options || {};
      var matched = false;
      tabs.forEach(function (tab) {
        var isActive = tab.getAttribute("data-install-mode-id") === modeId;
        tab.setAttribute("aria-selected", isActive ? "true" : "false");
        tab.setAttribute("tabindex", isActive ? "0" : "-1");
        if (isActive) {
          matched = true;
          if (options.focus) tab.focus();
          if (statusEl) {
            var template = installSwitcher.getAttribute("data-install-mode-announce") || "";
            var label = (tab.querySelector(".install-mode__tab-label") || {}).textContent || modeId;
            statusEl.textContent = template ? template.replace("{label}", label) : "";
          }
        }
      });
      if (!matched) return false;
      document.body.setAttribute("data-install-mode", modeId);
      try { window.localStorage.setItem(STORAGE_KEY, modeId); } catch (_) {}
      return true;
    }

    // Restore from storage if present and known.
    try {
      var stored = window.localStorage.getItem(STORAGE_KEY);
      if (stored) setMode(stored);
    } catch (_) {}

    installSwitcher.addEventListener("click", function (event) {
      var tab = event.target.closest('[role="tab"]');
      if (!tab) return;
      setMode(tab.getAttribute("data-install-mode-id"));
    });

    installSwitcher.addEventListener("keydown", function (event) {
      if (event.key !== "ArrowRight" && event.key !== "ArrowLeft" && event.key !== "Home" && event.key !== "End") return;
      var idx = tabs.indexOf(document.activeElement);
      if (idx === -1) return;
      var next = idx;
      if (event.key === "ArrowRight") next = (idx + 1) % tabs.length;
      else if (event.key === "ArrowLeft") next = (idx - 1 + tabs.length) % tabs.length;
      else if (event.key === "Home") next = 0;
      else if (event.key === "End") next = tabs.length - 1;
      event.preventDefault();
      setMode(tabs[next].getAttribute("data-install-mode-id"), { focus: true });
    });
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

    var indexCache = null;
    var indexPending = null;

    function loadIndex() {
      if (indexCache) return Promise.resolve(indexCache);
      if (indexPending) return indexPending;
      indexPending = fetch(indexUrl, { credentials: "same-origin" })
        .then(function (r) {
          if (!r.ok) throw new Error("index fetch " + r.status);
          return r.json();
        })
        .then(function (data) {
          indexCache = data;
          indexPending = null;
          return data;
        })
        .catch(function (err) {
          indexPending = null;
          console.warn("search index unavailable:", err);
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
      var groups = document.querySelectorAll(".group");
      var cards = document.querySelectorAll(".skill-card");

      if (!query) {
        for (var c = 0; c < cards.length; c++) cards[c].hidden = false;
        for (var g = 0; g < groups.length; g++) groups[g].hidden = false;
        statusEl.textContent = "";
        if (clearBtn) clearBtn.hidden = true;
        return;
      }

      if (clearBtn) clearBtn.hidden = false;
      if (!statusEl) return;

      loadIndex().then(function (records) {
        if (!records) return;
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
      var query = input.value.trim();
      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(function () {
        applyFilter(query);
      }, 80);
    });

    searchForm.addEventListener("reset", function () {
      setTimeout(function () { applyFilter(""); }, 0);
    });

    // Prefill from ?q=... — supports the SearchAction urlTemplate
    // (`/<lang>/?q={search_term_string}#skills`) and any shared link.
    var initialQuery = new URLSearchParams(window.location.search).get("q");
    if (initialQuery) {
      input.value = initialQuery;
      applyFilter(initialQuery.trim());
    }
  }

  // ----- clipboard ------------------------------------------------------
  document.addEventListener("click", function (event) {
    var btn = event.target.closest(".copy-btn");
    if (!btn) return;

    var target = null;
    var targetId = btn.getAttribute("data-copy-target");
    if (targetId) {
      target = document.getElementById(targetId);
    } else if (btn.hasAttribute("data-copy-active-install")) {
      // Skill-card button — copy whichever install command matches the active
      // body[data-install-mode]. CSS hides the others; we look them up by class.
      var mode = document.body.getAttribute("data-install-mode") || "claude-code";
      var container = btn.closest(".skill-card__installs");
      if (container) target = container.querySelector(".install--" + mode);
    }
    if (!target) return;

    var text = target.innerText.trim();

    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(
        function () { flashCopied(btn); },
        function () { fallbackPrompt(text); }
      );
    } else {
      fallbackPrompt(text);
    }
  });

  function flashCopied(btn) {
    var label = btn.querySelector(".copy-btn__label") || btn;
    var original = label.textContent;
    var copiedText = btn.getAttribute("data-copied-label") || "Copied";
    label.textContent = copiedText;
    btn.setAttribute("data-state", "copied");
    setTimeout(function () {
      label.textContent = original;
      btn.removeAttribute("data-state");
    }, 1500);
  }

  function fallbackPrompt(text) {
    window.prompt("Copy install command:", text);
  }
})();
