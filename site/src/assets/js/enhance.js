/*
 * Progressive enhancement — landing functions without this script.
 * Total budget: under 5 KB minified. No frameworks. No third-party imports.
 *
 * Features:
 *   - Copy-to-clipboard for install commands (with localized "Copied/Kopiert" flash)
 *   - Client-side skill search (lazy-loaded JSON index, in-place card filtering)
 */
(function () {
  "use strict";

  // ----- search ---------------------------------------------------------
  var searchForm = document.querySelector("[data-search]");
  if (searchForm) {
    var input = searchForm.querySelector("[data-search-input]");
    var clearBtn = searchForm.querySelector("[data-search-clear]");
    var statusEl = searchForm.querySelector("[data-search-status]");
    var indexUrl = searchForm.getAttribute("data-index-url");
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
  }

  // ----- clipboard ------------------------------------------------------
  document.addEventListener("click", function (event) {
    var btn = event.target.closest(".copy-btn");
    if (!btn) return;

    var targetId = btn.getAttribute("data-copy-target");
    var target = targetId ? document.getElementById(targetId) : null;
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
