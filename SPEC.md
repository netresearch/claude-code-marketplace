# SPEC: GitHub Page für `netresearch/claude-code-marketplace`

> Status: **Phase 1 (Specify) — final abgestimmt mit User am 2026-05-13** (zweiter Pass nach Reconciliation mit aktuellem [AGENTS.md `ca6a379`](https://github.com/netresearch/claude-code-marketplace/commit/ca6a379)). Bereit für Phase 2 (Plan).

---

## Bestätigte Annahmen & Entscheidungen

> Hinweis: Lokale Arbeitskopie war initial 30 Commits hinter `origin/main`. Erst nach `git show origin/main:AGENTS.md` wurde der echte Regel­kanon sichtbar. Die Entscheidungen unten reflektieren den **Remote-Stand**, nicht den initialen Stub.

1. **Repo-Identität:** `github.com/netresearch/claude-code-marketplace`, Default-Branch `main`, Pages noch nicht aktiviert (`has_pages: false`) → wird Teil des Deployments.
2. **Hosting-Pfad:** `https://netresearch.github.io/claude-code-marketplace/`. Keine Custom-Domain.
3. **Sprache:** **Volle Zweisprachigkeit (DE + EN)** auf allen Seiten. Default-Locale = EN (`/en/...`, plus Root `/` → 302 zu Accept-Language-Match oder fallback EN). DE unter `/de/...`. Bidirektionales `<link rel="alternate" hreflang>`.
4. **Marketplace-Regeln — drei Quellen:**
   - **Anthropic-Spec** ([code.claude.com/docs/en/plugin-marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)) — Pflichten für `marketplace.json` (Schema, kebab-case, reservierte Namen, Install-Syntax, owner-Attribution). **Keine Vorgaben für Pages-Content.**
   - **`AGENTS.md` (Repo-Regeln)** — Pflichten für Pages-Inhalte + Marketplace-Pflege:
     - § _GitHub Pages policy_: Marketplace soll Pages-Site als kanonische Discovery- & Storytelling-Schicht publizieren.
     - § _Marketplace as canonical discovery hub_: Pages besitzt Landing-Pages, Cross-Links, Related Skills, **indexable detail pages**.
     - § _Required fields per skill entry_: 13 Pflichtfelder pro Skill.
     - § _Canonical categories_: Enum mit 7 Werten — `development · devops · security · design · workflow · productivity · document`.
     - § _No orphan skills_: Jeder Skill mit Category + Use case + Related Skills + Repo + Install + Canonical Landing URL.
     - § _SEO and discovery rules_: erster Satz = Problem; keine generische AI-Boilerplate; Tech explizit benennen; Description ≤300 (target) / ≤500 (hard cap); Descriptions unique.
     - § _Mirroring rule_: skill-spezifische Metadaten kommen aus Skill-Repos (README oder zukünftiges `discovery.yaml`); Marketplace konsumiert, dupliziert nicht.
     - § _Agent workflow checklist (marketplace changes)_: 7-Punkte-Checkliste vor PR-Abschluss, inkl. `./scripts/validate.sh` lokal laufen.
     - **Hinweis:** Frühere Feb-5-Version von AGENTS.md erwähnte `bd` (beads) + „Landing the Plane" — beides ist in `ca6a379` **NICHT mehr enthalten** und damit kein Mandat. Tracking erfolgt über das **Claude Code Task feature** (`TaskCreate`/`TaskUpdate`/`TaskList`).
   - **`scripts/validate.sh`** — mechanischer Guard: erzwingt Category-Enum, Slug-Regex (`^[a-z0-9][a-z0-9-]{0,63}$`), Description-Limits, Eindeutigkeit, README-Catalog-Row pro Slug.
5. **Stack:** **Eleventy 3.x** + Eleventy-i18n-Plugin + Vanilla CSS + max. 5 KB Vanilla JS. Build-Time-Fetch der Skill-Repo-READMEs via GitHub-API.
6. **Brand:** Aus [`netresearch-branding-skill`](https://github.com/netresearch/netresearch-branding-skill) — Turquoise `#2F99A4`, Orange `#FF4D00`, Raleway + Open Sans (self-hosted WOFF2). Tokens via Skill-Tool-Invocation während Implementation.
7. **Datenquellen (mit Mirroring-Rule-konformer Konsumation):**
   - **Primär:** `.claude-plugin/marketplace.json` (40 Plugins, 7 Categories) — liefert Slug, Name, EN-Description, Category, Repo.
   - **Sekundär:** Skill-Repo-READMEs (build-time gefetcht via GitHub API) — liefert Use cases, Expected outputs, Context requirements, Related Skills.
   - **Tertiär:** README-Themen-Gruppierung (TYPO3 / OroCommerce / Code Quality & Security / DevOps / Productivity / Meta) als _Presentation Groups_ für die Landing — orthogonal zum Category-Enum, das Filter & SEO bedient.
   - **Fallback bei fehlenden Feldern:** dokumentierte „N/A (justified)"-Einträge in §_Known marketplace overrides_ der SPEC + AGENTS.md.
8. **Plugin-Detail-Pages:** **Phase 1, AGENTS.md-konform.** Pro Skill stabile canonical URL `/<lang>/skills/<slug>/`. Inhalt aus marketplace.json + Skill-Repo-README (build-time aggregiert).
9. **Analytics:** **Keine** clientseitigen Analytics. Statistik aus GitHub-Repo-Insights (built-in, kein Tracking-Code, kein Cookie-Banner-Bedarf).
10. **Visuals:** **Reines Typografie-Layout** — große Headings, Whitespace, Brand-Farb-Akzent, max. 24×24px SVG-Icons. Keine bildhaften Illustrationen.
11. **Hero:** **Kein Team-Foto**. Abstraktes SVG-Hero-Element (Code-Pattern / geometrische Komposition in Brand-Farben).
12. **Badges:** OpenSSF-Scorecard, License, Last-Updated im Footer.
13. **Internal Marketplace:** wird **nicht** auf der öffentlichen Page erwähnt (`git.netresearch.de/coding-ai/marketplace.git` bleibt rein intern).
14. **DE-Inhalte:** wo aus Quelle nicht ableitbar, wird der [`german-technical-writing-skill`](https://github.com/netresearch/german-technical-writing-skill) für Stil/Register herangezogen. Die DE-Variante ist nicht „übersetztes Englisch", sondern eigenständiger Text in deutschem Technical-Register.

---

## 1. Objective

### Was wir bauen
Eine **statische, narrative Landing-Page** auf GitHub Pages, die den Netresearch Claude Code Marketplace (`netresearch/claude-code-marketplace`) als **kuratiertes Skill-Ökosystem** präsentiert — nicht als trockene Plugin-Tabelle, sondern als Geschichte: _„Wie Netresearch-Engineers ihre Workflows mit Agent Skills automatisieren — und wie deine das auch tun können."_

### Wer das nutzt
- **Primär:** TYPO3- und PHP-Engineers, die einen AI-Coding-Workflow aufsetzen und vertrauenswürdige, kuratierte Skills suchen. Treffen die Page über Google, Twitter/X-Posts, Vorträge, README-Links.
- **Sekundär:** Entscheider (Tech Leads, CTOs), die Netresearch als Dienstleister evaluieren und sehen wollen, dass das Team aktiv im AI-Tooling-Space arbeitet.
- **Tertiär:** Andere Agent-Skill-Autoren, die das Repo als Referenz nehmen.

### Wie Erfolg aussieht (testbare Kriterien)

| Dimension | Zielwert | Messung |
| :-- | :-- | :-- |
| **Lighthouse Performance** (Mobile, Slow-4G-Drossel) | ≥ 95 | Lighthouse CI in PR-Checks |
| **Lighthouse Accessibility** | 100 | Lighthouse CI |
| **Lighthouse Best Practices** | ≥ 95 | Lighthouse CI |
| **Lighthouse SEO** | 100 | Lighthouse CI |
| **LCP** (Largest Contentful Paint) | < 2.0 s auf 4G | Web Vitals |
| **CLS** (Cumulative Layout Shift) | < 0.05 | Web Vitals |
| **TBT** (Total Blocking Time) | < 100 ms | Lighthouse |
| **Page-Size (gzipped HTML+CSS+JS)** | < 50 KB initial | `curl -sH 'accept-encoding: gzip'` |
| **JavaScript-Bytes** | ≤ 5 KB (nur progressive Enhancement, keine Frameworks) | Build-Bericht |
| **HTML-Validität** | 0 Errors | W3C Validator (CI) |
| **WCAG-Kontrast** | AA über das gesamte UI | axe-core CI-Run |
| **SEO-Indizierbarkeit** | Alle Pages in Sitemap, kein `noindex` außer 404 | Sitemap-Check |
| **Plugin-Datenkonformität** | Anzeige spiegelt `marketplace.json` 1:1 | Build-Diff gegen Schema |
| **Install-Befehl** | Exakt `/plugin marketplace add netresearch/claude-code-marketplace` (kopierbar mit einem Klick) | Manueller Check |

---

## 2. Tech Stack

| Komponente | Wahl | Begründung |
| :-- | :-- | :-- |
| **Static Site Generator** | **Eleventy 3.x** + `@11ty/eleventy-plugin-i18n` | Liest `.claude-plugin/marketplace.json` direkt; nativer i18n-Support via `@@locale@@`/permalink-Variablen; kein Runtime-JS; perfekt Lighthouse-tauglich. |
| **Templating** | Nunjucks (Eleventy-Default) | Iteration über Plugins, einfache i18n-Strukturen. |
| **CSS** | Vanilla CSS, ein Stylesheet, inlined critical CSS | Kein Framework. Brand-Tokens aus [`netresearch-branding-skill`](https://github.com/netresearch/netresearch-branding-skill). |
| **JavaScript** | Vanilla, optional, ≤ 5 KB | Copy-to-Clipboard, Filter, Lang-Switcher-Memo (`<a>`-basiert, JS nur als Enhancement). Page funktioniert ohne JS vollständig. |
| **Fonts** | Raleway + Open Sans, **self-hosted** (subsetted WOFF2) | Kein Google-Fonts-Fetch → besser Lighthouse + DSGVO. Subset auf Latin Extended. |
| **README-Fetch** | Build-Time, Node-Skript via `@octokit/rest` mit `GITHUB_TOKEN` | Holt READMEs aller 40 Skill-Repos einmal pro Build; Markdown-Parser (`marked`) extrahiert `## Use cases`, `## Related Skills`, `## Expected outputs`, `## Context requirements`. Toleranter Parser mit klar definierten Fallbacks für jede Skill, in der die Section fehlt. |
| **Caching** | `cache/skills-readme/{slug}.md` in CI-Cache | Spart API-Quota + Build-Zeit; Invalidate via `marketplace.json`-mtime und Skill-Repo `pushed_at`. |
| **Build-Output** | `_site/` (Eleventy-Default), deploy via Pages-Action | Standard-Pfad. |
| **CI/CD** | GitHub Actions: `actions/configure-pages@v5` + `actions/deploy-pages@v4` | Native GitHub-Pages-Deployment via Actions (nicht via `gh-pages`-Branch). |
| **Lighthouse-Gate** | `treosh/lighthouse-ci-action@v12` | Blockierender Check pro PR. Audit auf Landing + repräsentativer Detail-Page. |
| **HTML-Validierung** | `html-validate` lokal + CI | Pflicht-Check. |
| **A11y-Gate** | `@axe-core/cli` + Pa11y CI auf Landing + 3 zufälligen Detail-Pages | Repräsentativer Sample. |
| **Node-Version** | `lts/*` (`.nvmrc`) | Reproducible Builds. |
| **Package-Manager** | npm | Match zu anderen Netresearch-Repos. |

---

## 3. Commands

```bash
# Setup (einmalig)
npm install

# Lokale Entwicklung mit Live-Reload (http://localhost:8080)
npm run dev

# Produktions-Build → _site/
npm run build

# Statisches Vorschau-Hosting nach Build
npm run preview

# Linting (HTML, CSS, JS)
npm run lint

# Lighthouse lokal (gegen Produktions-Build)
npm run audit

# Sitemap-Validität
npm run check:sitemap

# Plugin-Daten-Konsistenz: bricht, wenn marketplace.json invalid
npm run check:data
```

---

## 4. Project Structure

```
/                                  Marketplace-Root (UNVERÄNDERT)
├── .claude-plugin/
│   └── marketplace.json           Single Source of Truth (40 Plugins) — NICHT verschieben
├── scripts/
│   └── validate.sh                Existierendes Validation-Skript — UNVERÄNDERT
├── README.md                      UNVERÄNDERT (oder ergänzt um Link auf Page am Ende)
├── AGENTS.md                      UNVERÄNDERT
│
├── SPEC.md                        ← Diese Datei
│
├── site/                          ← NEU: Eleventy-Quellen
│   ├── .eleventy.js               Eleventy-Config (Datenquellen, Filter, i18n)
│   ├── package.json
│   ├── package-lock.json
│   ├── .nvmrc
│   │
│   ├── scripts/
│   │   ├── fetch-readmes.js       Octokit-basierter Fetch aller 40 Skill-Repo-READMEs
│   │   ├── parse-readmes.js       Markdown→JSON, extrahiert Use cases / Related Skills / Expected outputs / Context requirements
│   │   ├── derive-related.js      Falls Related Skills aus README fehlen, ableiten aus Category + Tags + Themen-Gruppe
│   │   └── check-orphans.js       Validator: jede Skill hat alle 6 Pflicht-Verbindungen (siehe AGENTS.md §No orphan skills)
│   │
│   ├── src/
│   │   ├── _data/
│   │   │   ├── marketplace.js     Liest ../.claude-plugin/marketplace.json
│   │   │   ├── skills.js          Merge marketplace.json + fetched READMEs → kanonische Skill-Objects
│   │   │   ├── i18n/
│   │   │   │   ├── en.json        UI-Strings + Storytelling-Copy EN
│   │   │   │   └── de.json        UI-Strings + Storytelling-Copy DE (eigenständig verfasst, nicht maschinell)
│   │   │   ├── categories.json    7-Werte-Enum + DE/EN-Labels + Icons
│   │   │   ├── groups.json        Themen-Gruppen aus README (TYPO3 / OroCommerce / …) + DE/EN-Labels
│   │   │   ├── overrides.json     Known Marketplace Overrides (AGENTS.md §Known marketplace overrides)
│   │   │   └── site.json          Site-Metadaten, OG-Defaults, Repo-URL
│   │   │
│   │   ├── _includes/
│   │   │   ├── layouts/
│   │   │   │   ├── base.njk       HTML-Skeleton, lang-Attribut dynamisch, hreflang-Pärchen, OG/Twitter/JSON-LD
│   │   │   │   ├── landing.njk
│   │   │   │   └── skill.njk      Detail-Page-Layout (one per skill)
│   │   │   └── partials/
│   │   │       ├── header.njk     Mit Lang-Switcher
│   │   │       ├── footer.njk     Mit Badges (Scorecard, License, Last-Updated)
│   │   │       ├── skill-card.njk
│   │   │       ├── install-block.njk
│   │   │       ├── related-skills.njk
│   │   │       └── breadcrumbs.njk
│   │   │
│   │   ├── assets/
│   │   │   ├── css/
│   │   │   │   ├── tokens.css     Brand-Tokens (CSS Custom Properties) aus netresearch-branding-skill
│   │   │   │   └── main.css       Layout + Komponenten
│   │   │   ├── fonts/             WOFF2-Subsets Raleway + Open Sans (Latin + Latin-Ext)
│   │   │   ├── img/               SVG-Icons (24×24), OG-Image-Templates (1200×630)
│   │   │   └── js/
│   │   │       └── enhance.js     Copy-to-Clipboard, Filter, Lang-Switcher-Memo
│   │   │
│   │   ├── en/
│   │   │   ├── index.njk          EN-Landing
│   │   │   ├── skills/
│   │   │   │   └── {{ slug }}.njk Pagination-driven: 1 Page pro Skill (canonical /en/skills/<slug>/)
│   │   │   ├── about.njk
│   │   │   └── 404.njk
│   │   │
│   │   ├── de/
│   │   │   ├── index.njk          DE-Landing (eigenständig getextet, kein Übersetzungs-Echo)
│   │   │   ├── skills/
│   │   │   │   └── {{ slug }}.njk Pagination-driven: 1 Page pro Skill (canonical /de/skills/<slug>/)
│   │   │   ├── about.njk
│   │   │   └── 404.njk
│   │   │
│   │   ├── index.njk              Root: serverless Accept-Language-Redirect via <meta http-equiv> + JS-Enhancement; Fallback-Link auf /en/ und /de/
│   │   ├── sitemap.xml.njk        Beide Locales, alle Skill-Detail-Pages
│   │   └── robots.txt
│   │
│   └── tests/
│       ├── lighthouse/            lighthouserc.json (Budget + Assertions, Landing + 3 Detail-Pages)
│       ├── a11y/                  pa11y-config.json
│       └── parser/                Unit-Tests für parse-readmes.js
│
└── .github/
    └── workflows/
        ├── validate.yml           UNVERÄNDERT
        ├── security.yml           UNVERÄNDERT
        └── pages.yml              ← NEU: Fetch READMEs + Eleventy-Build + Lighthouse-CI + Pages-Deploy
```

**Begründung der Trennung:** Alles Page-bezogene lebt in `site/`. Repo-Root bleibt sauber, `.claude-plugin/marketplace.json` an oberster Stelle, kein Build-Artefakt im Root.

---

## 5. Code Style

### HTML (Templates)
- **Semantisches HTML5**: `<main>`, `<article>`, `<nav>`, `<section>`, `<header>`, `<footer>`.
- Eine `<h1>` pro Page. Heading-Hierarchie ohne Sprünge.
- Bilder mit explizitem `width` + `height` (verhindert CLS) und `loading="lazy"` außer LCP-Bild.
- Externe Links: `rel="noopener"` wenn `target="_blank"`.

### CSS
- CSS Custom Properties in `tokens.css`, Layout-Code in `main.css`.
- Mobile-First, Breakpoints in `em` (375 / 640 / 1024 / 1440).
- Keine `!important`. Keine Inline-Styles außer Critical CSS im `<head>`.
- BEM-light (`block__element--modifier`) für Komponenten-Klassen.

**Beispiel — Plugin-Card-Markup (Nunjucks → HTML):**

```njk
{# site/src/_includes/partials/plugin-card.njk #}
<article class="plugin-card plugin-card--{{ plugin.category }}">
  <header class="plugin-card__header">
    <h3 class="plugin-card__title">
      <a href="https://github.com/{{ plugin.source.repo }}"
         rel="noopener"
         aria-label="View {{ plugin.name }} source repository on GitHub">
        {{ plugin.name }}
      </a>
    </h3>
    <span class="plugin-card__category" aria-label="Category">
      {{ plugin.category | capitalize }}
    </span>
  </header>
  <p class="plugin-card__description">{{ plugin.description }}</p>
  <footer class="plugin-card__footer">
    <code class="plugin-card__install">/plugin install {{ plugin.name }}@netresearch-claude-code-marketplace</code>
    <button type="button" class="copy-btn"
            data-copy="/plugin install {{ plugin.name }}@netresearch-claude-code-marketplace"
            aria-label="Copy install command for {{ plugin.name }}">
      Copy
    </button>
  </footer>
</article>
```

### JavaScript
- ES2022, keine Build-Steps (kein Bundler — Browser lädt ein einziges Modul).
- `defer` auf `<script>` im `<head>`.
- Feature-Detection für `navigator.clipboard`, sonst Fallback auf `prompt()`.
- Keine externen Bibliotheken.

---

## 6. Testing Strategy

| Test-Layer | Tool | Was wird geprüft | Wann |
| :-- | :-- | :-- | :-- |
| **HTML-Validität** | `html-validate` | Alle `_site/**/*.html` valide | PR + Push |
| **CSS-Linting** | `stylelint-config-standard` | Konsistenz, keine Errors | PR + Push |
| **JavaScript-Linting** | `eslint` (vanilla preset) | Syntax + Style | PR + Push |
| **Marketplace-JSON** | Existierendes `scripts/validate.sh` | Schema, Categories-Enum, Slug-Regex, Description-Limits, README-Catalog-Row | PR + Push (unverändert) |
| **Build smoke test** | `npm run build` | Generiert `_site/` ohne Errors, alle 40 Skill-Cards rendern, 40 EN- + 40 DE-Detail-Pages existieren | PR + Push |
| **README-Parser-Tests** | Jest oder Node-Test-Runner | Robust gegen fehlende Sections, korrekte Markdown→JSON-Konversion | PR + Push |
| **AGENTS.md Compliance Check (No-Orphan)** | `site/scripts/check-orphans.js` | Pro Skill: Category ∈ Enum, ≥1 Use case, Related Skills (oder dokumentiertes „none (justified)"), Repo-Link, Install-Pfad, Canonical Landing URL — siehe AGENTS.md §No orphan skills | PR + Push (blocking) |
| **AGENTS.md SEO-Copy Check** | Eigener Lint-Script | Verbietet Boilerplate-Phrasen („ultimate assistant", „supercharge…"), prüft Tech-Name-Präsenz | PR + Push (warning, manuelle Review) |
| **Lighthouse Performance/A11y/SEO** | `treosh/lighthouse-ci-action@v12` | Budget aus Objective auf Landing **und** auf 3 randomly-picked Detail-Pages | PR + Push (blocking) |
| **Accessibility deep-scan** | `@axe-core/cli` + Pa11y | Keine WCAG-2.1-AA-Verletzungen | PR + Push |
| **Sitemap-Validität** | Eigener Check | Alle EN- + DE-URLs enthalten, jeder `<url>` hat `<xhtml:link rel='alternate' hreflang>` für die andere Sprache | PR + Push |
| **hreflang-Konsistenz** | Eigener Check | Jede EN-Page verweist auf existierende DE-Counterpart und umgekehrt; `x-default` gesetzt | PR + Push |
| **OG/Twitter-Tags** | Eigener Check-Skript | Pro Page: `og:title`, `og:description`, `og:image`, `og:url`, `og:locale`, `og:locale:alternate`, `twitter:card` | PR + Push |
| **Broken-Link-Check** | `lychee` GitHub Action | Keine 404 in internen/externen Links, alle Skill-Repo-Links lösen auf | Nightly Cron + PR |
| **Structured-Data-Validität** | Eigener Check via Schema.org-Validator | JSON-LD `Organization`, `WebSite`, `CollectionPage`, `SoftwareApplication` pro Skill, `BreadcrumbList` korrekt | PR + Push |
| **Visual regression** | Optional Phase-2 | — | — |

**Coverage-Ziel:** Jeder im Objective genannte Erfolgs-Wert + jede AGENTS.md-Pflicht hat einen automatisierten Check.

---

## 7. Narrative & Storytelling-Konzept

Die Page **erzählt** statt zu **listen** — getrennt für **EN** und **DE**, mit **eigenständig verfasstem** DE-Text (kein maschinelles Echo).

### Landing-Page (`/en/`, `/de/`)

| Section | Story-Beat EN | Story-Beat DE |
| :-- | :-- | :-- |
| **Hero** | _„You ship code. Your agent should know your stack."_ | _„Du lieferst Software. Dein Agent kennt deinen Stack."_ |
| **The problem** | _„Generic AI doesn't know TYPO3 conventions, PSR-12 quirks, or your DDEV setup."_ | _„Generische AI kennt deine TYPO3-Konventionen nicht, nicht eure PSR-12-Eigenheiten, nicht euer DDEV-Setup."_ |
| **The marketplace** | _„40 curated skills. One install. Works in Claude Code, Cursor, Copilot, Codex, Gemini CLI, Amp, Goose, OpenCode."_ | _„40 kuratierte Skills. Ein Install. Funktioniert in 8+ Agents."_ |
| **By category** | _„Pick by what you ship."_ — Grid über die 7 canonical Categories, jeweils mit Themen-Gruppen-Heading (TYPO3 / OroCommerce / …). | _„Wähle nach Lieferobjekt."_ — gleiche Struktur. |
| **The story** | _„Built by Netresearch — a TYPO3 agency in Leipzig running production for LMS, e-Commerce, enterprise CMS."_ | _„Gebaut von Netresearch — TYPO3-Agentur in Leipzig, die LMS, e-Commerce und Enterprise-CMS produktiv betreibt."_ |
| **How it works** | 3 Schritte: `Add → Install → Use`. Code kopierbar. Plus alternative `npx skills add ...` für Non-Claude-Agents. | gleiche Struktur. |
| **Open standard** | _„Agent Skills spec — portable across tools."_ Link zu [agentskills.io](https://agentskills.io). | _„Agent-Skills-Spec — portabel zwischen Tools."_ |
| **CTA Footer** | _„Star the repo. Open an issue. Submit a skill."_ + Badges. | _„Repo starren. Issue eröffnen. Skill einreichen."_ + Badges. |

### Detail-Page pro Skill (`/<lang>/skills/<slug>/`) — AGENTS.md §No orphan skills konform

| Block | Inhalt (Quelle) |
| :-- | :-- |
| **Breadcrumb** | `Home / Skills / <Category> / <Skill>` mit BreadcrumbList-JSON-LD. |
| **H1: Display Name** | aus marketplace.json `name` (kebab→Title-Case via Filter). |
| **Problem statement** | erster Satz der `description` aus marketplace.json (AGENTS.md §SEO copy: „first sentence states the concrete problem"). |
| **Full description** | restliche `description` + ggf. extrahierter README-Lead. |
| **Install block** | `/plugin install <slug>@netresearch-claude-code-marketplace` + alternativ `npx skills add ...`. Copy-Buttons. |
| **Category badge** | Canonical Category (aus 7-Werte-Enum), mit Filter-Link zur Landing. |
| **Use cases** | Bullets aus Skill-Repo-README `## Use cases`-Section. Fallback: aggregiert aus marketplace.json + Themen-Gruppen-Kontext. |
| **Expected outputs** | aus README `## Expected outputs` oder Fallback. |
| **Context requirements** | aus README `## Context requirements` oder Fallback. |
| **Related Skills** | aus README oder abgeleitet via `derive-related.js` (Category-Match + Themen-Gruppe). Falls keine echten Verwandten existieren: explizit „No closely related skills in this marketplace yet — see the full catalog." Niemals erfunden. |
| **Repository link** | aus marketplace.json `source.repo`. |
| **Tags** | aus marketplace.json `tags` (falls existiert) oder abgeleitet. |
| **Lang-Switcher** | Link auf `/<other-lang>/skills/<slug>/` mit `hreflang`. |
| **JSON-LD** | `SoftwareApplication` mit `name`, `description`, `applicationCategory`, `url`, `sameAs` (Repo-URL), `author` (Organization=Netresearch). |

---

## 8. SEO-Plan (konkret + testbar)

### Technical SEO
- `<title>`: ≤ 60 Zeichen, Format `{{ page.title }} · Netresearch Skills Marketplace`.
- `<meta name="description">`: ≤ 155 Zeichen, pro Page individuell, pro Sprache eigenständig getextet.
- `<link rel="canonical">` auf jeder Page (locale-spezifisch).
- **Hreflang-Pärchen:** jede EN-Page hat `<link rel="alternate" hreflang="en">` und `<link rel="alternate" hreflang="de">` zur DE-Counterpart. `<link rel="alternate" hreflang="x-default" href="…/en/…">`. Konsistenz via Test.
- `sitemap.xml` mit `<xhtml:link rel="alternate" hreflang>` pro `<url>`.
- `robots.txt` mit Sitemap-Verweis.
- `<html lang="en">` bzw. `<html lang="de">` dynamisch.
- Strukturierte URLs: `/en/`, `/en/skills/<slug>/`, `/en/about/`, analog `/de/`.
- Trailing-Slash konsistent (alle Pages mit `/`).

### Structured Data (JSON-LD) — AGENTS.md §SEO konform
- **Organization** auf jeder Page (Netresearch DTT GmbH, `sameAs`: Twitter, LinkedIn, GitHub-Org).
- **WebSite** auf den Landing-Pages mit `SearchAction` (clientseitige Skill-Filter).
- **CollectionPage + ItemList** auf Landing mit allen 40 Skills als `SoftwareApplication`-Refs.
- **SoftwareApplication** pro Skill auf Detail-Page: `name`, `description` (lokalisierte Variante), `applicationCategory` (mappt auf Category-Enum), `url` (canonical Detail-URL), `sameAs` (Repo-URL), `author` (Organization=Netresearch), `softwareHelp` (Repo-README-URL).
- **BreadcrumbList** auf Detail-Pages und About-Page.

### Social / OG
- **OG-Image:** 1200×630, build-time per Sharp generiert aus SVG-Template pro Skill (titel + category badge). Landing nutzt generisches OG-Image mit „40 skills".
- **Twitter:** `summary_large_image`.
- **og:type:** `website` für Landings, `article` für Detail-Pages, `profile` für About.
- **og:locale:** `en_US` bzw. `de_DE`, plus `og:locale:alternate` zur anderen Sprache.

### Index-Hygiene
- 404-Pages haben `<meta name="robots" content="noindex">`.
- Skill-externe Repos werden **nicht** in `sitemap.xml` aufgenommen (nur eigene URLs).
- Root `/` redirected/nutzt `<meta http-equiv="refresh">` auf `/en/` als Sicherheitsnetz (Accept-Language ist auf statischem Hosting nicht serverseitig auswertbar; JS-Enhancement schaltet auf DE wenn Browser-Locale `de*` ist).

---

## 9. Performance-Plan (für Lighthouse 95+)

| Hebel | Umsetzung |
| :-- | :-- |
| **Critical CSS inlined** | `~3 KB` für Hero im `<head>`, Rest via `<link rel="preload">` + `media="print"`-Switch. |
| **Fonts** | WOFF2-Subsets, `font-display: swap`, `<link rel="preload" as="font" crossorigin>` für den initial sichtbaren Cut. |
| **Bilder** | SVG wo möglich. PNG/JPG mit `width`/`height`, `loading="lazy"` außer LCP. AVIF/WebP optional. |
| **JS** | `defer`, optional ganz weglassbar. |
| **HTTP** | GitHub Pages liefert HTTP/2, gzip + brotli automatisch. |
| **Third Party** | **NULL** Third-Party-Skripte (kein Analytics in Phase 1; Plausible Phase 2 wenn gewünscht). |
| **Resource Hints** | `<link rel="preconnect" href="https://github.com">` für CTA-Klicks. |
| **Cache** | Asset-Pfade mit Content-Hash für 1-Jahr-Cache (z. B. `main.abc123.css`). |
| **No layout shift** | `aspect-ratio` auf allen Media-Wrappers. |

---

## 10. Boundaries

### Always do (immer)
- Alle Plugin-Daten aus `.claude-plugin/marketplace.json` lesen. Keine duplizierte Pflege.
- HTML semantisch + WCAG-AA.
- Build-Output `_site/` ignorieren in `.gitignore`.
- Lighthouse-Gate als blocking PR-Check.
- Conventional Commits (`feat(site):`, `fix(site):`, `chore(site):`).
- DCO-Sign-off + signierte Commits (`-S --signoff`).
- **Tracking + Workflow:**
  - Implementierungs-Arbeit über das **Claude Code Task feature** tracken — eine Task pro Sub-Phase (2a–2g) mit Komponenten als Description.
  - PRs statt Direct-Push auf `main` (per User-Memory `feedback_always_use_prs.md`) — pro Sub-Phase ein Branch + PR.
  - **AGENTS.md `ca6a379` §Agent workflow checklist (marketplace changes)** vor jedem PR-Abschluss durchlaufen: 13-Felder-Check, DACH-DE-Description-Check, No-Orphan-Check, SEO-erster-Satz-Check, Related-Skills-Real-or-Justified-Check, Link-Resolve-Check, `./scripts/validate.sh` lokal.
  - **bd (beads):** ist kein Team-Tool mehr (in `ca6a379` nicht mehr erwähnt). `.beads/`-Verzeichnis ist Legacy-State, bleibt unangetastet.

### Ask first (vor Umsetzung kurz rückversichern)
- Custom-Domain einrichten (`skills.netresearch.de` o. ä.) — bedeutet DNS-Änderung + CNAME-File.
- Analytics einbauen (Plausible, Matomo, GA4) — DSGVO-Implikationen.
- Plugin-Detail-Pages mit READMEs aus Source-Repos pullen — Build-Komplexität ↑.
- Internationalisierung (DE zusätzlich zu EN).
- Newsletter-Signup oder Lead-Form.
- Bilder von Mitarbeitenden (DSGVO + Einwilligung).
- Externe Schriften statt selbst-gehostet.

### Never do (nie ohne expliziten User-Auftrag)
- `.claude-plugin/marketplace.json` aus dem Root verschieben oder umbenennen — würde `/plugin marketplace add netresearch/claude-code-marketplace` brechen.
- README oder AGENTS.md überschreiben.
- Plugin-Daten manuell in HTML hardcoden (Drift garantiert).
- Tracking-Pixel, Third-Party-Scripts, Google Fonts, Google Analytics, Tag-Manager.
- Cookies oder LocalStorage ohne Notwendigkeit (= ohne Cookie-Banner-Bedarf bleiben).
- AI-Attribution in Commits (per Netresearch-CLAUDE.md).
- Marketplace-Name in Pages-Texten umbenennen — er ist als `netresearch-claude-code-marketplace` (kebab-case, slug aus `marketplace.json:name`) verankert.

### Marketplace-Konformität — Anthropic-Spec
- **Install-Befehl exakt:** `/plugin marketplace add netresearch/claude-code-marketplace` (GitHub `owner/repo`-Shorthand wie in Anthropic-Doku).
- **Plugin-Install exakt:** `/plugin install <name>@netresearch-claude-code-marketplace` (Slug aus `marketplace.json.name`, nicht aus Repo-Name).
- **Reservierte Namen nicht impersoniert:** Page macht klar, dass dies eine **community/vendor** Marketplace ist, kein Anthropic-Official.
- **Plugin-Identitäten unverändert:** Slugs, Categories, EN-Descriptions, Repo-URLs werden aus JSON gelesen.

### Marketplace-Konformität — AGENTS.md (Repo-Eigenregeln)
- **§ Marketplace as canonical discovery hub:** Pages ist die kanonische Discovery-Surface. Jede Skill bekommt eine stabile, indexable Detail-Page mit canonical URL `/<lang>/skills/<slug>/`.
- **§ Required fields per skill entry:** Jede Detail-Page füllt alle 13 Pflichtfelder _oder_ markiert „N/A (justified)" in §_Known marketplace overrides_ unten:
  1. Slug — aus marketplace.json
  2. Display Name — aus Slug abgeleitet (Title-Case)
  3. Repository URL — aus marketplace.json
  4. Install URL — gerendert auf Detail-Page
  5. EN Description — aus marketplace.json
  6. DE Description — eigenständig getextet (mit Hilfe von [`german-technical-writing-skill`](https://github.com/netresearch/german-technical-writing-skill))
  7. Category — aus marketplace.json, aus Enum
  8. Tags — aus README oder abgeleitet
  9. Use cases — aus README oder Fallback
  10. Expected outputs — aus README oder Fallback
  11. Context requirements — aus README oder Fallback
  12. Related Skills — aus README oder via `derive-related.js` oder „none (justified)"
  13. Canonical landing page URL — generierte URL `/<lang>/skills/<slug>/`
- **§ Canonical categories:** ausschließlich `development · devops · security · design · workflow · productivity · document`. Page-Code nutzt das Enum, kein freier Text.
- **§ No orphan skills:** `site/scripts/check-orphans.js` prüft pre-build, dass jede Skill alle 6 Pflicht-Verbindungen hat.
- **§ SEO and discovery rules:** Erster Satz jeder Detail-Page-Description = Problem-Aussage. Verbotsliste Boilerplate-Phrasen wird von Lint-Skript geprüft. Tech-Namen explizit (TYPO3, PHP, OroCommerce, …).
- **§ Mirroring rule:** Skill-spezifische Inhalte werden aus Skill-Repos konsumiert, nicht dupliziert. Detail-Pages linken zum Skill-Repo, kopieren keine prozeduralen READMEs.
- **§ Known marketplace overrides:** intentionale Abweichungen (z. B. fehlende Quell-Daten) werden in einer dedizierten Tabelle dokumentiert (siehe §13).
- **Owner-Attribution:** „Netresearch DTT GmbH" im Footer + im JSON-LD `Organization`-Block, in beiden Sprachen.

---

## 11. Aufgelöste Entscheidungen (vormals "Open Questions")

| Frage | Antwort | Begründung |
| :-- | :-- | :-- |
| Custom-Domain? | Nein | User-Entscheidung 2026-05-13 |
| Analytics? | Nein (nur GitHub-Repo-Insights) | User-Entscheidung — keine Extra-Tools, kein Tracking |
| Sprache? | EN only | User-Entscheidung |
| Plugin-Detail-Pages? | Phase 2 | User-Entscheidung |
| Story-Visual? | Reines Typografie-Layout | Default akzeptiert |
| Team-Foto? | Kein Foto, abstraktes SVG-Hero | Default akzeptiert (DSGVO-frei) |
| Badges? | Ja (Scorecard, License, Updated) | User-Entscheidung |
| Internal Marketplace erwähnen? | Nein, rein extern | User-Entscheidung |

**Verbleibende offene Punkte:** keine. SPEC ist bereit für Phase 2.

---

## 12. Acceptance Criteria (Phase 4 done = wenn das alles stimmt)

- [ ] `npm run build` läuft fehlerfrei lokal und in CI.
- [ ] `_site/` enthält: 2× Landing (`/en/`, `/de/`) + 2× About + 80× Skill-Detail-Pages (40 Slugs × 2 Sprachen) + Sitemap + Robots + 404s.
- [ ] **Alle 40 Skills haben eine canonical Detail-Page** `/<lang>/skills/<slug>/` (AGENTS.md §_Marketplace as canonical discovery hub_).
- [ ] **No-Orphan-Check grün:** jede Skill hat Category + Use case + Related Skills (oder dokumentiertes „none (justified)") + Repo + Install + Canonical URL (AGENTS.md §_No orphan skills_).
- [ ] **Hreflang-Konsistenz-Check grün:** jede EN-Page hat existierende DE-Counterpart und umgekehrt; `x-default` gesetzt.
- [ ] **Categories ausschließlich aus 7-Werte-Enum** (validator-confirmed): `development · devops · security · design · workflow · productivity · document`.
- [ ] **Descriptions:** alle ≤ 500 Zeichen (hard cap), Warning für > 300 Zeichen, unique (validate.sh-konform).
- [ ] **SEO-Copy-Lint** grün: keine Boilerplate-Phrasen, Tech-Namen explizit, erster Satz = Problem-Aussage.
- [ ] **Lighthouse-CI:** Performance ≥ 95, A11y = 100, BP ≥ 95, SEO = 100 auf Landing **und** 3 random Detail-Pages.
- [ ] **`gh api repos/netresearch/claude-code-marketplace/pages`** liefert deployed Page-URL (`has_pages: true`).
- [ ] **`curl https://raw.githubusercontent.com/netresearch/claude-code-marketplace/main/.claude-plugin/marketplace.json`** weiterhin valide JSON (regression check — Pages-Site darf marketplace.json-Discovery nicht stören).
- [ ] axe-core + Pa11y CI-Run: 0 Violations.
- [ ] **JSON-LD-Validität:** Schema.org-Validator akzeptiert `Organization`, `WebSite`, `CollectionPage + ItemList`, `SoftwareApplication`, `BreadcrumbList`.
- [ ] **Lychee Broken-Link-Check:** 0 broken Links auf Landing, Detail-Pages, Sitemap.
- [ ] Manuelle Smoke-Tests:
  - Hero-CTA kopiert exakten Install-Befehl `/plugin marketplace add netresearch/claude-code-marketplace`.
  - Pro Skill-Detail-Page: Plugin-Install-Befehl `/plugin install <slug>@netresearch-claude-code-marketplace` ist 1-Klick-kopierbar.
  - Lang-Switcher zwischen `/en/skills/<slug>/` ↔ `/de/skills/<slug>/` funktioniert.
  - Page rendert sauber in Chrome, Firefox, Safari (jeweils current + N-1).
  - Page rendert ohne JS (Progressive Enhancement).
  - Reduced-Motion-Preference wird respektiert.
- [ ] **Existierende Marketplace-CI (`scripts/validate.sh`)** ist **unverändert** und grün.
- [ ] **Existierende Security-Workflows (`security.yml`)** weiter grün, Pages-Workflow tangiert sie nicht.
- [ ] README erhält am Ende einen Link auf die neue Page.
- [ ] Implementierungs-Arbeit war über Claude Code Tasks getrackt (7 Sub-Phase-Tasks 2a–2g); alle Tasks completed.
- [ ] Letzter Session-Stand sauber: `git status` zeigt „up to date with origin" auf dem Initiative-Branch, alle Sub-Phase-PRs gemerged.

---

## 13. Known marketplace overrides (lebende Tabelle gemäß AGENTS.md §_Known marketplace overrides_)

Diese Tabelle dokumentiert **intentionale Abweichungen** vom „one canonical source per fact"-Prinzip. Sie wird sowohl in der SPEC als auch in AGENTS.md gepflegt (bei Bedarf — initial leer bei Phase-1-Start):

| Slug | Field | Marketplace value (Page) | Reason | Decided |
|---|---|---|---|---|
| _(empty at Phase 1 start; populated when build encounters missing source data)_ | | | | |

**Pflicht-Workflow bei Override-Erstellung:** Wenn build-time-Fetch eine README-Section nicht findet und kein automatisches Fallback greift, generiert `site/scripts/parse-readmes.js` einen Override-Eintrag mit Reason „README section absent on YYYY-MM-DD" und committet ihn als Artifact für Review.

---

## 14. Nicht im Scope (out-of-scope dieser Spec)

- `discovery.yaml` in den 40 Skill-Repos anlegen (separates Vorhaben; sobald vorhanden, ersetzt es das README-Parsing).
- Clientseitige Volltext-Suche jenseits einfacher Category/Tag-Filter.
- Authentifizierte Bereiche (Login, Skill-Submission-Form).
- Newsletter-Backend, RSS-Feed.
- Dynamische API-Endpoints, serverseitige Logik.
- Übersetzung in weitere Sprachen (FR, IT, ES) jenseits DE+EN.
- Visual-Regression-Tests (Phase-2-Kandidat).
- Versionierung pro Skill (Skill-Versionen sind heute nicht in marketplace.json gepinnt; Phase-2-Thema).

---

**Nach Freigabe dieser Spec startet Phase 2 (Plan):** technischer Implementierungsplan mit Reihenfolge, Risiken, Verifikations-Checkpoints und parallelisierbaren Tasks. Tracking via `bd` (per AGENTS.md §Workflow).
