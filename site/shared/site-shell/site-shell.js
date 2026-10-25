(() => {
  function syncTheme(picker, theme) {
    picker.dataset.preference = theme.preference;
    for (const radio of picker.querySelectorAll('input[name="nr-shell-theme"]')) radio.checked = radio.value === theme.preference;
    const label = picker.querySelector('input:checked').closest('label').querySelector('span').textContent;
    const summary = picker.querySelector('summary');
    const name = picker.querySelector('legend').textContent + ': ' + label;
    summary.setAttribute('aria-label', name);
    summary.title = name;
  }
  for (const shell of document.querySelectorAll('[data-nr-shell]')) {
    if (shell.dataset.ready) continue;
    const picker = shell.querySelector('[data-nr-theme-picker]');
    const menu = shell.querySelector('[data-nr-mobile-menu]');
    const disclosures = [picker, menu];
    const theme = window.nrSiteTheme;
    const close = (details, returnFocus = false) => {
      if (!details.open) return;
      details.open = false;
      if (returnFocus) details.querySelector('summary').focus();
    };
    for (const details of disclosures) {
      details.addEventListener('toggle', () => {
        if (details.open) for (const other of disclosures) if (other !== details) close(other);
      });
      details.addEventListener('keydown', event => {
        if (event.key === 'Escape' && details.open) { event.preventDefault(); close(details, true); }
      });
      details.addEventListener('focusout', event => {
        if (event.relatedTarget && !details.contains(event.relatedTarget)) close(details);
      });
    }
    document.addEventListener('click', event => {
      for (const details of disclosures) if (!details.contains(event.target)) close(details);
    });
    for (const link of menu.querySelectorAll('a')) link.addEventListener('click', () => close(menu));
    const desktop = window.matchMedia('(min-width: 1024px)');
    desktop.addEventListener('change', event => { if (event.matches) close(menu); });
    const keepThemeFocusVisible = () => requestAnimationFrame(() => {
      const focused = picker.querySelector('input:focus');
      if (picker.open && focused) focused.scrollIntoView({ block: 'nearest' });
    });
    picker.addEventListener('focusin', keepThemeFocusVisible);
    window.addEventListener('resize', keepThemeFocusVisible);
    if (theme) {
      for (const radio of picker.querySelectorAll('input[name="nr-shell-theme"]')) {
        radio.addEventListener('change', () => { if (radio.checked) theme.setPreference(radio.value); });
      }
      window.addEventListener('nr-theme-change', () => syncTheme(picker, theme));
      syncTheme(picker, theme);
      picker.hidden = false;
    }
    shell.dataset.ready = 'true';
  }
  for (const menu of document.querySelectorAll('[data-nr-page-menu]')) {
    if (menu.dataset.ready) continue;
    const close = (returnFocus = false) => {
      if (!menu.open) return;
      menu.open = false;
      if (returnFocus) menu.querySelector('summary').focus();
    };
    menu.addEventListener('keydown', event => {
      if (event.key === 'Escape' && menu.open) { event.preventDefault(); close(true); }
    });
    menu.addEventListener('focusout', event => { if (event.relatedTarget && !menu.contains(event.relatedTarget)) close(); });
    menu.addEventListener('click', event => { if (event.target.closest('a')) close(); });
    document.addEventListener('click', event => { if (!menu.contains(event.target)) close(); });
    window.matchMedia('(min-width: 1024px)').addEventListener('change', event => { if (event.matches) close(); });
    const keepPageFocusVisible = () => requestAnimationFrame(() => {
      const focused = menu.querySelector('a:focus');
      if (menu.open && focused) focused.scrollIntoView({ block: 'nearest' });
    });
    menu.addEventListener('focusin', keepPageFocusVisible);
    window.addEventListener('resize', keepPageFocusVisible);
    menu.dataset.ready = 'true';
  }
})();
