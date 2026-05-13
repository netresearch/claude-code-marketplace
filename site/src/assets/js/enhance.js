/*
 * Progressive enhancement — landing functions without this script.
 * Total budget: under 5 KB minified. No frameworks. No third-party imports.
 */
(function () {
  "use strict";

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
    label.textContent = "Copied";
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
