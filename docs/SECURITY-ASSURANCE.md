<!-- SPDX-License-Identifier: MIT -->
<!-- SPDX-FileCopyrightText: Netresearch DTT GmbH -->

# Security assurance case — claude-code-marketplace

This document states what a user can expect from this repository in terms of security, and argues why that expectation holds. Every claim names the file that implements it. Reporting a vulnerability: see the [security policy](https://github.com/netresearch/.github/blob/main/SECURITY.md).

## What the repository ships

| Part | Files | Runs where |
| --- | --- | --- |
| Marketplace catalogue | `.claude-plugin/marketplace.json` | Read by Claude Code after `/plugin marketplace add netresearch/claude-code-marketplace`; not executed |
| Catalogue validation | `scripts/validate.sh`, `scripts/overlap-report.py`, `.githooks/pre-commit` | In CI (`.github/workflows/validate.yml`) and on contributors' machines |
| Discovery site generator | `site/` (Eleventy templates under `site/src/`, data layer under `site/src/_data/`, build scripts under `site/scripts/`) | In CI (`.github/workflows/pages.yml`) and on contributors' machines |
| Discovery site | the static HTML, CSS, JavaScript, JSON and images built into `site/_site/` | Served by GitHub Pages at `https://netresearch.github.io/claude-code-marketplace/`, rendered in visitors' browsers |

The repository contains no skill code: each catalogue entry names a skill repository (`source.repo`), and Claude Code fetches the skill from there. The site has no server component, no user accounts and no cookies; its only form is the search field, whose search runs in the browser against the site's own index (`enhance.js`). The only data it keeps about a visitor is the chosen install mode, in the visitor's own browser (`localStorage` in `site/src/assets/js/enhance.js`).

## Security requirements

1. Text taken from skill repositories at build time cannot inject HTML elements into a page, and cannot place a script link in the use-case, expected-output and context-requirement lists of a skill detail page.
2. The site loads no third-party script, font or analytics service.
3. A GitHub token used by the build is read from the environment only and never written to the repository or the built site.
4. The workflows grant each job only the token permissions it needs.
5. Nothing committed to the repository contains a secret.
6. A pull request that adds a dependency with a known vulnerability of severity high or critical fails a check.

## Actors and trust boundaries

- **Maintainers and contributors** change the catalogue, the site and the workflows through pull requests (see [Governance](https://github.com/netresearch/.github/blob/main/GOVERNANCE.md)). Data committed here is trusted: `marketplace.json`, the files under `site/src/_data/` (display names, German descriptions, install overrides, locale strings) and the templates.
- **Skill repositories.** `site/scripts/fetch-readmes.js` fetches the README and the latest release of each of the 40 repositories that `marketplace.json` names — all of them under `github.com/netresearch/` — through the GitHub API (`@octokit/rest`). The README text crosses a trust boundary: it is written by whoever can change that repository, it is not reviewed here, and it is cached in `site/cache/skills-readme/` (not committed, `site/.gitignore`). `site/scripts/parse-readme.js` extracts sections from it by string matching; it does not execute or render the Markdown.
- **GitHub API.** `fetch-readmes.js` authenticates with `GITHUB_TOKEN` from the environment when it is set and anonymously otherwise. In CI the token is the job's `GITHUB_TOKEN`, which the reusable build workflow exposes to the build phase and not to the dependency install (`expose-github-token: build` in `pages.yml`).
- **Site visitors.** Visitors receive static files from GitHub Pages. The only script file is `site/src/assets/js/enhance.js`, loaded from the site itself, besides the inline locale redirect of the root page (`site/src/index.njk`). `enhance.js` fetches the site's own search index (`search-index.json`) and never inserts HTML: it sets text with `textContent`, toggles `hidden`, sets attributes and the search field's value, copies install commands to the clipboard, and remembers the chosen install mode in `localStorage`.
- **Claude Code users.** Claude Code reads `marketplace.json` and installs the skill repositories it names. What a skill does is decided in its own repository.
- **CI.** Workflows run on GitHub-hosted runners and call reusable workflows from `netresearch/.github`. `sync-private-copy.yml` force-pushes `main` to the private copy `netresearch/claude-code-marketplace-P` on every push to `main`, with a write deploy key stored as `PRIVATE_COPY_DEPLOY_KEY` in the `private-copy` environment.

## Threats and countermeasures

| Threat | Countermeasure | Evidence |
| --- | --- | --- |
| README text from a skill repository injects HTML elements into a detail page (CWE-79) | Templates are rendered with Nunjucks autoescaping, which is on by default: Eleventy 3.1.6 passes no `autoescape` option, and Nunjucks 3.2.4 then enables it. Use cases, expected outputs and context requirements go through the `inlineMarkdown` filter, which HTML-escapes the whole input before it converts any inline Markdown | `site/.eleventy.js` (`inlineMarkdown`, `escapeHtml`); `site/src/_includes/layouts/skill.njk`; `site/package-lock.json` |
| A Markdown link in the use-case, expected-output or context-requirement lists carries a `javascript:` or other script URL (CWE-79) | `inlineMarkdown` emits a link only when its target matches an allowlist (`http:`, `https:`, `mailto:`, relative paths and fragments); any other target stays plain text | `site/scripts/safe-href.js` (`SAFE_URL_PREFIX`, `isSafeHref`); `site/.eleventy.js` (`inlineMarkdown`) |
| A link in the related-skills section of a README carries a `javascript:` or other script URL (CWE-79) | `parseReadme` keeps a related-skill link only when its target matches the same allowlist | `site/scripts/parse-readme.js`; `site/scripts/safe-href.js`; `site/tests/install-methods.test.js` |
| Text in the OG images injects SVG markup | `generate-og-images.js` XML-escapes every text value before building the SVG that `sharp` renders | `site/scripts/generate-og-images.js` (`escapeXml`) |
| A third-party script or tracker is added to the site | No template loads an external script, font or stylesheet; the decision is recorded in ADR-0003 | `site/src/_includes/layouts/base.njk`; `docs/decisions/0003-no-client-side-analytics.md` |
| A build token leaks | The token is read from `process.env.GITHUB_TOKEN` only; the README cache holds README text, ETag and release metadata, not the token | `site/scripts/fetch-readmes.js`; `site/.gitignore` |
| A secret is committed | Betterleaks scans the Git history on every pull request to `main` and every push to `main`, and fails on a finding | `.github/workflows/security.yml` |
| A dependency with a known vulnerability is added | Dependency review fails a pull request on vulnerabilities of severity high or critical; Renovate proposes updates | `.github/workflows/security.yml`; `renovate.json` |
| An npm package runs code while it is installed | CI installs `site/` with `npm ci --ignore-scripts` from the lock file | `.github/workflows/pages.yml`, `.github/workflows/refresh-visual-snapshots.yml`; `site/package-lock.json` |
| A third-party action is replaced under its tag | Third-party actions are referenced by full commit SHA | `.github/workflows/validate.yml`, `.github/workflows/refresh-visual-snapshots.yml`, `.github/workflows/sync-private-copy.yml` |
| A workflow token is misused | `security.yml`, `codeql.yml`, `dco.yml`, `auto-merge-deps.yml`, `validate.yml` and `sync-private-copy.yml` set `permissions: {}` at the top and grant each job what it needs; `pages.yml` grants permissions per job, and only its `deploy` job, which runs on `main` only, gets `pages: write` and `id-token: write`; `refresh-visual-snapshots.yml` runs on manual dispatch only and grants `contents: write` and `pull-requests: write` to open its snapshot pull request | `.github/workflows/*.yml` |
| Pull request code runs with a write token | `auto-merge-deps.yml` is the only `pull_request_target` workflow; it calls one reusable workflow and does not check out the pull request | `.github/workflows/auto-merge-deps.yml` |
| A crafted argument redirects the overlap report to another file (CWE-22) | `overlap-report.py` resolves `--marketplace` and rejects a path outside the repository; it writes nothing and prints the report to standard output | `scripts/overlap-report.py` (`_resolve_within_repo`, `main`) |
| Insecure code in the site scripts, the Python script or the workflows | CodeQL analyses `actions`, `javascript-typescript` and `python` on every pull request, on every push to `main` and weekly | `.github/workflows/codeql.yml` |
| A catalogue entry breaks the catalogue | `validate.sh` checks JSON syntax, required fields, unique names and descriptions, the category and value-type enums, slug format and the README catalogue row | `scripts/validate.sh`; `.github/workflows/validate.yml`; `.githooks/pre-commit` |

## Secure design principles applied

- **Minimal attack surface:** the published site is static. It has no server code, no accounts and no cookies, its search runs in the browser, and it loads no third-party resource.
- **Least privilege:** workflows grant token permissions per job; write permissions for Pages exist only in the `deploy` job (`.github/workflows/pages.yml`).
- **Escape by default:** templates rely on Nunjucks autoescaping; `| safe` appears only on the page content inside the base layout, after `inlineMarkdown`, which escapes first, and after `dump`, which serialises data to JSON (`site/src/`).
- **Allowlist over blocklist:** link targets taken from README text (the rendered bullets and the related-skills links) are matched against permitted schemes rather than filtered for forbidden ones (`site/scripts/safe-href.js`).
- **Data, not code:** README text from skill repositories is parsed by string matching and never evaluated (`site/scripts/parse-readme.js`).

## What a user cannot expect

- This repository does not review or vouch for the skills it lists. A catalogue entry names a repository without a commit or release (`.claude-plugin/marketplace.json`), so Claude Code installs what that repository provides when the user installs it.
- The site trusts the data committed here. Values from `marketplace.json` and `site/src/_data/` are written into JSON-LD blocks with `dump | safe` and into link targets without an allowlist (`site/src/_includes/layouts/skill.njk`, `site/src/_includes/partials/install-mode-switcher.njk`); changes to those files are reviewed like code.
- The site sets no Content Security Policy.
- A README that cannot be fetched does not fail the CI build: `fetch-readmes.js` fails only when `STRICT_FETCH=1` is set, which `pages.yml` does not do. The detail page is then built from the catalogue data alone.
- Only the DCO check is a required check on `main`. The build, the tests, Lighthouse, visual regression, CodeQL, Betterleaks and dependency review run on every pull request, but a failure does not block the merge by ruleset.
- The reusable workflows this repository calls are referenced by branch (`@main`), not by commit (`.github/workflows/*.yml`).
