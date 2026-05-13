# PLAN: GitHub Page für `netresearch/claude-code-marketplace`

> **Status:** Phase 2 (Plan). Folgt aus [`SPEC.md`](./SPEC.md) v2 (final, abgestimmt 2026-05-13 gegen [AGENTS.md `ca6a379`](https://github.com/netresearch/claude-code-marketplace/commit/ca6a379)). Phase 3 (Tasks) und Phase 4 (Implement) folgen nach Freigabe dieses Plans.

---

## 1. Architektur-Überblick

```
┌─────────────────────────────────────────────────────────────────────┐
│ BUILD-TIME PIPELINE (GitHub Actions auf push / pull_request / cron) │
└─────────────────────────────────────────────────────────────────────┘

  .claude-plugin/marketplace.json   ◄── Single Source of Truth (40 plugins)
            │
            ▼
   ┌─────────────────────┐         ┌──────────────────────────────────┐
   │ fetch-readmes.js    │ ──────► │ cache/skills-readme/{slug}.md    │
   │ (Octokit, 40 calls) │         │ (CI cache, invalidated by ETag)  │
   └─────────────────────┘         └──────────────────────────────────┘
            │                                       │
            └───────────────┬───────────────────────┘
                            ▼
                  ┌──────────────────────────┐
                  │ parse-readmes.js         │ ── Markdown→JSON extraction
                  │   - Use cases            │    (## sections, fallback rules)
                  │   - Expected outputs     │
                  │   - Context requirements │
                  │   - Related Skills       │
                  └──────────────────────────┘
                            │
                            ▼
              ┌──────────────────────────────────┐
              │ derive-related.js                │ ── falls README leer:
              │   Related = same-category + same │    Category- + Themen-Gruppen-
              │   theme-group + curated overrides│    Heuristik
              └──────────────────────────────────┘
                            │
                            ▼
            ┌────────────────────────────────────────┐
            │ build-skills-data.js                   │
            │   Merge marketplace.json + parsed +    │
            │   derived → canonical skills[] objects │
            │   (one per slug, with EN/DE fields)    │
            └────────────────────────────────────────┘
                            │
                            ▼
              ┌──────────────────────────────────┐
              │ check-orphans.js   (blocking)    │ ── AGENTS.md §No orphan skills
              │ check-seo-copy.js  (warning)     │ ── AGENTS.md §SEO and discovery
              │ check-categories.js (blocking)   │ ── 7-Werte-Enum
              └──────────────────────────────────┘
                            │
                            ▼
            ┌────────────────────────────────────────┐
            │ Eleventy build (Nunjucks templates)    │
            │   /en/         landing                 │
            │   /de/         landing                 │
            │   /en/skills/{40 slugs}/  detail-pages │
            │   /de/skills/{40 slugs}/  detail-pages │
            │   /en/about/, /de/about/               │
            │   /sitemap.xml, /robots.txt, /404      │
            │   /                                    │
            └────────────────────────────────────────┘
                            │
                            ▼
                  ┌────────────────────┐
                  │ _site/  (~85 HTML) │
                  └────────────────────┘
                            │
                            ▼
       ┌────────────────────────────────────────┐
       │ Quality gates (parallel, all blocking): │
       │   - Lighthouse CI (Landing + 3 random)  │
       │   - axe-core / Pa11y (Landing + sample) │
       │   - html-validate                       │
       │   - hreflang-consistency-check          │
       │   - sitemap-check                       │
       │   - lychee broken-link-check (advisory) │
       └────────────────────────────────────────┘
                            │
                            ▼
            actions/upload-pages-artifact + deploy-pages
                            │
                            ▼
           https://netresearch.github.io/claude-code-marketplace/
```

---

## 2. Komponenten + Abhängigkeiten

| ID | Komponente | Hängt ab von | Liefert |
| :-- | :-- | :-- | :-- |
| **C1** | Repo-Hygiene + Pages-Aktivierung | — | Pages-Setting `has_pages: true`, `.github/workflows/pages.yml`-Stub |
| **C2** | `site/`-Skelett + npm-Init | C1 | `site/package.json`, `.nvmrc`, `.eleventy.js`, `_site/.gitignore` |
| **C3** | Brand-Tokens + CSS-Grundgerüst | C2, [`netresearch-branding-skill`](https://github.com/netresearch/netresearch-branding-skill) | `tokens.css`, `main.css`, Schriften-Subsets |
| **C4** | Datenquelle Tier 1 (`marketplace.json` → `_data/marketplace.js`) | C2 | Eleventy-Data-File, gerendert valide |
| **C5** | i18n-Setup + UI-Strings | C2 | `_data/i18n/en.json`, `_data/i18n/de.json`, Permalink-Konvention `/<lang>/...` |
| **C6** | Landing-Page-Layout EN | C3, C4, C5 | `/en/` rendert, alle 40 Skill-Cards |
| **C7** | Landing-Page-Layout DE (Text eigenständig) | C6, [`german-technical-writing-skill`](https://github.com/netresearch/german-technical-writing-skill) | `/de/` rendert |
| **C8** | README-Fetch (`fetch-readmes.js`) + Caching | C2 | `cache/skills-readme/{slug}.md` × 40 |
| **C9** | README-Parser (`parse-readmes.js`) | C8 | Strukturierte Felder pro Skill |
| **C10** | Related-Derivation (`derive-related.js`) | C9 | Related-Skills pro Skill (real oder „none (justified)") |
| **C11** | Datenquelle Tier 2 (`_data/skills.js` merge) | C4, C9, C10 | Kanonisches Skills-Array mit allen 13 Pflichtfeldern |
| **C12** | No-Orphan-Linter (`check-orphans.js`) | C11 | Build bricht bei Verletzung |
| **C13** | SEO-Copy-Linter (`check-seo-copy.js`) | C11 | Warnings (kein Build-Break) |
| **C14** | Category-Enum-Check | C11 | Build bricht bei Abweichung vom 7-Werte-Enum |
| **C15** | Detail-Page-Layout EN | C6, C11 | `/en/skills/<slug>/` × 40 |
| **C16** | Detail-Page-Layout DE | C7, C11 | `/de/skills/<slug>/` × 40 |
| **C17** | Sitemap + Robots + 404 | C6, C7, C15, C16 | `/sitemap.xml` (mit hreflang), `/robots.txt`, `/en/404.html`, `/de/404.html` |
| **C18** | Lang-Switcher + hreflang-Pärchen | C6, C7, C15, C16 | Bidirektionale Links zwischen EN/DE-Pendants |
| **C19** | Structured Data (JSON-LD) | C6, C15 | `Organization`, `WebSite`, `CollectionPage`, `SoftwareApplication`, `BreadcrumbList` |
| **C20** | OG-Image-Generator (Sharp/SVG) | C6, C15 | 81 OG-Images (1 Landing + 80 Detail) im Build |
| **C21** | Lighthouse-CI-Config | C17, C19, C20 | `lighthouserc.json` + GHA-Step |
| **C22** | A11y-Checks (axe + Pa11y) | C17 | GHA-Step |
| **C23** | Hreflang-Konsistenz-Check | C18 | Eigener Skript, blocking |
| **C24** | GHA-Workflow `pages.yml` (kompletter Build + Deploy) | C8, C11–C20 | Push-Auslösung → Live-Deploy |
| **C25** | README-Footer-Link auf neue Page | C24 (nach erstem Live-Deploy) | README-Edit |
| **C26** | Task-Hygiene + finaler Cleanup | alle | Saubere Issue-Liste, Push erfolgreich |

---

## 3. Implementierungs-Reihenfolge

### Phase 2a: Foundation (1 PR, ~2h)
1. **C1** Pages aktivieren via `gh api -X POST repos/.../pages` (build_type: workflow). Initial leerer `pages.yml`.
2. **C2** `site/`-Skelett, `npm init`, Eleventy + i18n-Plugin installieren, Dummy-Page rendert lokal.
3. **C3** Brand-Tokens + CSS-Grundgerüst per `Skill`-Invocation netresearch-branding (CSS + Schriften).
4. **C4** Datenquelle Tier 1 funktioniert: `_data/marketplace.js` liest JSON, ein simples Test-Template iteriert über 40 Plugins.

**Verifikation 2a:** `npm run build` rendert in `_site/` eine Dummy-Page mit Plugin-Count = 40 und Brand-Farben. Manueller Check + erstes Smoke-Test in CI (Build grün).

### Phase 2b: Landing EN (1 PR, ~3h)
5. **C5** i18n-Setup, Permalinks, UI-Strings EN.
6. **C6** Landing-Page-Layout EN narrative-konform aus SPEC §7, mit allen 40 Skill-Cards, Themen-Gruppen-Überschriften aus README, 7-Category-Filter.

**Verifikation 2b:** `/en/` rendert sauber, Lighthouse-Test isoliert auf EN-Landing ≥ 95/100/95/100. Visual-Inspektion in Browser. PR auf main, merge.

### Phase 2c: README-Fetch + Parser (1 PR, ~4h)
7. **C8** `fetch-readmes.js` mit Octokit, GITHUB_TOKEN, ETag-Cache, Rate-Limit-Handling.
8. **C9** `parse-readmes.js` extrahiert Sektionen, robust gegen Variationen.
9. **C10** `derive-related.js` mit Category + Themen-Gruppen-Heuristik.
10. **C11** `_data/skills.js` merged → kanonische Skills mit allen 13 Pflichtfeldern.
11. **C12, C13, C14** Linter-Scripts.

**Verifikation 2c:** `npm run check:data` listet 40 Skills mit allen 13 Feldern (gefüllt oder explizit `N/A (justified)`). No-Orphan-Check grün. Category-Enum-Check grün. SEO-Copy-Linter gibt Warnungen-Liste aus, die Page-CTA-Texte aber nicht.

### Phase 2d: Detail-Pages EN (1 PR, ~3h)
12. **C15** Detail-Page-Layout EN, Pagination über alle 40 Slugs.
13. **C19** JSON-LD `SoftwareApplication` + `BreadcrumbList` pro Detail-Page.
14. **C20** OG-Image-Generator für 40 EN-Detail-Pages.

**Verifikation 2d:** `/en/skills/<slug>/` × 40 vorhanden, Lighthouse-Test auf 3 random Detail-Pages ≥ 95/100/95/100. JSON-LD via Schema.org-Validator.

### Phase 2e: DE-Variante komplett (1 PR, ~5h, mit german-technical-writing-skill)
15. **C7** Landing DE — Text **eigenständig** verfasst via `german-technical-writing-skill`.
16. **C16** Detail-Pages DE — Texte ebenso eigenständig.
17. **C18** Lang-Switcher + hreflang-Pärchen.
18. **C20** OG-Images für 40 DE-Detail-Pages.

**Verifikation 2e:** `/de/` + `/de/skills/<slug>/` × 40 rendern. Hreflang-Konsistenz-Check (`C23`) grün. Spot-Check: deutsche Texte lesen sich nicht wie übersetztes Englisch.

### Phase 2f: Quality Gates + Deploy (1 PR, ~3h)
19. **C17** Sitemap mit hreflang-Pärchen, Robots, 404s.
20. **C21** Lighthouse-CI als blocking GHA-Step.
21. **C22** axe + Pa11y CI.
22. **C23** Hreflang-Check als blocking GHA-Step.
23. **C24** Vollständiger `pages.yml`-Workflow: cache-restore → fetch-readmes (mit Skip wenn cache hit) → build → quality gates → upload-artifact → deploy-pages.

**Verifikation 2f:** `gh api repos/netresearch/claude-code-marketplace/pages` zeigt `status: built`. Browser-Test der Live-URL: alle 85 Pages aufrufbar, Lang-Switcher funktioniert, kein Lighthouse-Regress.

### Phase 2g: Cleanup + Cross-Linking (1 PR, ~1h)
24. **C25** README-Footer-Link auf neue Page.
25. **C26** Tasks schließen, finaler Status-Check (alle PRs gemerged, Pages live).

**Gesamt-Aufwand-Schätzung:** ~21h netto, 7 PRs, ~7–10 Arbeitstage je nach Parallelisierung und Review-Latenz.

---

## 4. Was läuft parallel, was ist sequenziell

### Parallel möglich (keine Abhängigkeit):
- **Phase 2a Schritt 3 (CSS) ∥ Schritt 4 (Datenquelle Tier 1)** — beide nach Skelett.
- **Phase 2c Schritte 7–10 (Fetch + Parser + Derive)** parallel zu **Phase 2b (Landing EN)** — Landing braucht in v1 nur marketplace.json-Felder; Detail-Pages brauchen die geparsten READMEs.
- **OG-Image-Generator (C20)** kann gegen Stub-Daten parallel entwickelt werden.
- **Lighthouse + axe + Pa11y + Hreflang-Check** laufen in CI parallel als unabhängige Jobs.

### Sequenziell zwingend:
- Detail-Pages (C15, C16) hängen an Skills-Datenquelle (C11), die an Parser (C9) hängt, der an Fetch (C8) hängt.
- DE-Texte (C7, C16) müssen **nach** EN-Strukturen (C6, C15), damit Layout stabil ist — sonst doppelter Text-Aufwand bei Layout-Änderungen.
- Deploy (C24) erst nach allen Quality Gates.

---

## 5. Risiken + Mitigation

| Risiko | Wahrscheinlichkeit | Impact | Mitigation |
| :-- | :-- | :-- | :-- |
| **GitHub-API-Rate-Limit** beim Fetch von 40 READMEs | Mittel | Build bricht | ETag-Cache + `If-None-Match`, Cache in GHA-Cache, Token mit ausreichend Quota (`GITHUB_TOKEN` reicht: 1000 req/h für public repos). Fetch-Sequential mit kurzem Sleep wenn Rate-Limit-Header < 100 verbleibend. |
| **README-Strukturen inkonsistent** zwischen Skill-Repos | Hoch | Felder leer → Override-Inflation | Toleranter Parser, klar definierte Fallbacks, Override-Eintrag mit Reason. Parallel: Skill-Repo-Pflege-Issues anlegen für die Top-5-Probleme. |
| **DE-Texte als „übersetztes Englisch"** | Hoch | AGENTS.md §German Description-Verletzung in Geist | german-technical-writing-skill _ZWINGEND_ einsetzen, kein direktes EN→DE-Mapping. Reviewer (Mensch) liest DE-Korpus quer. |
| **Lighthouse-Performance-Score < 95** auf Detail-Pages durch JSON-LD-Bloat | Niedrig | Block | JSON-LD minimiert, kein Inline-Bild-base64, Lazy-Load aller Below-Fold-Elemente. Page-Budget für Detail-Page: ≤ 60 KB gzipped HTML+CSS+inline-JS. |
| **Hreflang-Inkonsistenz** durch fehlende DE/EN-Paare | Mittel | SEO-Penalty | Blocking-Check vor Deploy. Bei jeder neuen Skill: Build bricht, wenn nur EN- ohne DE-Counterpart existiert. |
| **Pages-Workflow scheitert beim ersten Deploy** wegen fehlender Pages-Konfiguration | Hoch | Verzögerung | Phase 2a Schritt 1 separat als erstes PR, isoliert testbar via Dummy-Page vor jeglicher Komplexität. |
| **Plugin-Liste wächst** während Implementation (neue Skills) | Mittel | Texte veraltet | Datenquellen sind Pflicht-Single-Source — neue Skills landen automatisch in der Page beim nächsten Build. Kein manueller Sync nötig. Limit: keine narrative Spezial-Texte pro Skill in der UI-Layer. |
| **Branding-Skill ändert Tokens** während Implementation | Niedrig | Brand-Drift | Tokens als versionierte Source-of-Truth einlesen, nicht inline kopieren. Skill-Update = CSS-Token-Update. |
| **README-Catalog-Row-Check schlägt** im validate.sh fehl wegen neuer Plugins | Mittel | CI rot | Pages-Workflow ändert validate.sh NICHT. Falls neue Plugins in marketplace.json landen ohne README-Update, ist das ein bestehender Repo-Workflow-Bug, kein Pages-Bug. |
| **Skills-Daten-Mismatch** zwischen marketplace.json und README-Tabelle | Mittel | UI inkonsistent | Page baut nur aus marketplace.json. README-Tabelle ist für menschliche Leser, nicht für Build. Doppel-Pflege bleibt — wird in Phase 2 NICHT gelöst. |

---

## 6. Verifikations-Checkpoints

Nach jeder Sub-Phase MUSS folgender Mini-Audit grün sein, **bevor** die nächste Sub-Phase startet:

| Sub-Phase | Manuelle Checks | Automatisierte Checks |
| :-- | :-- | :-- |
| 2a Foundation | Build läuft lokal | CI rendert `_site/`, plugin-count assertion |
| 2b Landing EN | `/en/` rendert visuell sauber im Browser | Lighthouse-CI auf Landing ≥ 95/100/95/100 |
| 2c Fetch/Parser | Stichprobe: 3 random READMEs korrekt geparst | `check:data` listet alle 40 mit 13 Feldern; No-Orphan grün; Category-Enum grün |
| 2d Detail EN | Stichprobe: 3 random `/en/skills/<slug>/` visuell sauber | Lighthouse auf 3 random Detail-Pages ≥ 95/100/95/100; JSON-LD valide |
| 2e DE komplett | Native-Speaker-Review: DE-Texte lesen sich natürlich | hreflang-check grün; Pa11y auf DE-Landing + DE-Detail-Stichprobe |
| 2f Deploy | Live-URL erreichbar, Pages-Status `built` | Workflow ende-zu-ende grün, alle Quality-Gates grün |
| 2g Cleanup | Tasks-Liste sauber, alle Sub-Phase-PRs gemerged, `git status` „up to date" | — |

---

## 7. Locked Decisions (2026-05-13, User-Mandat „mach wie du denkst")

Folgende Punkte sind nach User-Freigabe fixiert und gehen so in Phase 3 (Tasks):

| # | Entscheidung | Begründung |
| :-- | :-- | :-- |
| **1** | **Permalink-Format:** `/en/skills/<slug>/` + `/de/skills/<slug>/` | Saubere SEO-Trennung, hreflang-friendly, kanonische URLs ohne Query-Strings. |
| **2** | **Default-Root `/`:** statisches `<meta http-equiv="refresh" content="0; url=/en/">` + Sicherheits-Link auf beide Sprachen. JS-Enhancement (`enhance.js`) prüft `navigator.language.startsWith('de')` und re-routed sofort auf `/de/`. Funktioniert auch ohne JS (degradiert nach EN). | Static-Hosting kann Accept-Language nicht serverseitig auswerten. Meta-Refresh ist hreflang-kompatibel (`x-default`-Konvention). |
| **3** | **OG-Image-Generator:** Sharp + SVG-Template build-time, dynamisch pro Skill. | 81 OG-Images sind manuell nicht wartbar. Dynamische Generation = automatischer Sync mit Content. Keine Binär-Diffs im Repo. |
| **4** | **README-Cache:** Per-Repo ETag via Octokit `If-None-Match`, persistiert in GHA-Cache mit Key `skills-readme-{marketplace.json-sha}-{workflow-version}`. | Refresh nur bei realer Source-Änderung. Minimiert API-Quota. Stale-Builds vermieden via wöchentlichem Cron. |
| **5** | **CI-Trigger:** `on: push` (main, alle Pfade) + `pull_request` (main) + `workflow_dispatch` + `schedule: cron weekly`. Kein Pfad-Filter (Komplexität spart kaum, riskiert Lücken). | Einfacher Trigger-Set, deterministisch. ETag-Cache verhindert teure unnötige Fetches bei reinen Page-only-Pushes. |
| **6** | **Cron-Rebuild:** **Weekly**, `cron: '0 3 * * 0'` (Sonntag 03:00 UTC). | Skill-Repo-READMEs ändern sich nicht stündlich. Weekly fängt regelmäßige Updates ein, ohne CI-Quota zu verbrennen. `workflow_dispatch` für Ad-hoc-Rebuilds. |
| **7** | **Task-Granularität:** **7 Tasks = 7 Sub-Phasen** (2a–2g) im Claude Code Task feature, jede mit Komponenten-Checkliste in der Description. Kein `bd`, kein GitHub Issue. | 26 Tasks wären zu granular; 7 Sub-Phasen mappen 1:1 auf 7 PRs. |
| **8** | **Branch-Name:** `feat/github-pages-storytelling` für SPEC+PLAN-PR. Pro Sub-Phase eigener Branch: `feat/pages-2a-foundation`, `feat/pages-2b-landing-en`, etc. | Konvention `feat/pages-2{x}-{kurzname}` macht PR-Reihenfolge offensichtlich. |

---

## 8. Vor-Phase-3-Setup-Checkliste

Bevor Phase 3 (Tasks-Erstellung) startet:

- [ ] User hat diesen Plan freigegeben oder konkret korrigiert.
- [ ] Frühe Entscheidungs-Punkte (§7) aufgelöst.
- [ ] `gh` CLI authentifiziert (`gh auth status`).
- [ ] Branch erstellt: `feat/github-pages-storytelling` (oder vom User vorgegeben).
- [ ] SPEC.md + PLAN.md committet im PR-Branch + DCO-Sign-off + signiert.
- [ ] PR gegen `main` eröffnet als Tracking-PR für die ganze Initiative (oder pro Sub-Phase ein eigenes PR — auch eine §7-Entscheidung).

---

## 9. Out-of-Plan (= Phase-3-Detail)

Diese Items kommen **erst in Phase 3** als konkrete Tasks:

- Per-Sub-Phase Tasks mit Acceptance Criteria (Komponenten als Checklist im Body).
- Pro-Task-File-Liste (welche Dateien geändert/erstellt werden).
- Eleventy-Config-Details (collections, computed data, filters).
- Konkrete CSS-Token-Werte (Spacing-Scale, Type-Scale — kommen aus netresearch-branding-skill).
- DE-Storytelling-Copy pro Section (Inhalte, nicht Struktur — Struktur ist in SPEC §7 schon definiert).
- Per-Skill-Fallback-Texte für leere README-Sections.

---

**Nach Freigabe dieses Plans:** Phase 3 erstellt 7 Sub-Phase-Tasks via Claude Code Task feature (`TaskCreate`), jeweils mit Acceptance Criteria, Verifikations-Schritt und betroffenen Files.
