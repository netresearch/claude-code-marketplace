/* Inline this file early in <head>; it intentionally has no DOM-control hooks. */
(() => {
  if (window.nrSiteTheme) return;
  const valid = value => ['system', 'light', 'dark'].includes(value);
  const media = window.matchMedia('(prefers-color-scheme: dark)');
  function readPreference() {
    try {
      const canonical = localStorage.getItem('nr-theme');
      if (canonical !== null) return valid(canonical) ? canonical : 'system';
      for (const key of ['theme', 'nr-color-theme', 'nrllm-theme']) {
        const legacy = localStorage.getItem(key);
        if (valid(legacy)) return legacy;
      }
    } catch {
      // Storage may be blocked; the current preference remains in page memory.
    }
    return 'system';
  }
  let preference = readPreference();
  let effective;
  function apply() {
    effective = preference;
    if (preference === 'system') effective = media.matches ? 'dark' : 'light';
    document.documentElement.dataset.theme = effective;
    document.documentElement.dataset.themePreference = preference;
    document.documentElement.classList.toggle('dark', effective === 'dark');
    document.documentElement.style.colorScheme = effective;
    window.dispatchEvent(new CustomEvent('nr-theme-change', { detail: { preference, effective } }));
  }
  window.nrSiteTheme = {
    get preference() { return preference; },
    get effective() { return effective; },
    setPreference(value) {
      if (!valid(value)) return;
      preference = value;
      try { localStorage.setItem('nr-theme', value); } catch {
        // Keep this explicit choice in memory when persistence is unavailable.
      }
      apply();
    },
  };
  media.addEventListener('change', () => { if (preference === 'system') apply(); });
  window.addEventListener('storage', event => {
    if (event.key === 'nr-theme' || event.key === null) { preference = readPreference(); apply(); }
  });
  apply();
})();
