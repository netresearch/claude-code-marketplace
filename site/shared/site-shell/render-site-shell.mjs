import { readFileSync } from 'node:fs';
import copy from './site-shell.copy.json' with { type: 'json' };

const escapeHtml = value => String(value).replace(/[&<>"']/g, char => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#x27;' })[char]);
const destinations = {
  de: { home: 'https://netresearch.github.io/de/', projects: 'https://netresearch.github.io/de/projekte/', stack: 'https://netresearch.github.io/modularer-ki-stack-page/', impact: 'https://netresearch.github.io/maint/de/' },
  en: { home: 'https://netresearch.github.io/', projects: 'https://netresearch.github.io/projects/', stack: 'https://netresearch.github.io/modularer-ki-stack-page/en/', impact: 'https://netresearch.github.io/maint/' },
};

function safeUrl(value) {
  if (typeof value !== 'string' || !value || /[\u0000-\u0020]/.test(value) || value.startsWith('//') || (/^[a-z][\w+.-]*:/i.test(value) && !/^https?:/i.test(value))) throw new TypeError('Expected a safe URL');
  return value;
}

export function renderSiteHeader(config, optionalTemplateOverride) {
  if (!['de', 'en'].includes(config.lang)) throw new TypeError('Expected lang de or en');
  if (config.active != null && !Object.hasOwn(destinations.en, config.active)) throw new TypeError('Unknown active navigation item');
  const text = copy[config.lang];
  const values = { ...text, assetBase: safeUrl(config.assetBase).replace(/\/$/, ''), deUrl: safeUrl(config.languageUrls?.de), enUrl: safeUrl(config.languageUrls?.en), contactHref: safeUrl(config.contactHref), deCurrent: config.lang === 'de' ? 'page' : 'false', enCurrent: config.lang === 'en' ? 'page' : 'false' };
  const globalLinks = Object.entries(destinations[config.lang]).map(([key, href]) => `<a class="nr-shell-link" href="${escapeHtml(href)}" aria-current="${key === config.active ? 'page' : 'false'}">${escapeHtml(text[key])}</a>`).join('');
  const template = optionalTemplateOverride ?? readFileSync(new URL('./site-shell.html', import.meta.url), 'utf8');
  return template.replace(/{{(\w+)}}/g, (_, key) => key === 'globalLinks' ? globalLinks : escapeHtml(values[key] ?? ''));
}

/** toolsHtml is trusted, static build markup only; never pass request/user HTML. */
export function renderPageNavigation(config, optionalTemplateOverride) {
  if (!['de', 'en'].includes(config.lang)) throw new TypeError('Expected lang de or en');
  if (typeof config.title !== 'string' || !config.title || !Array.isArray(config.links)) throw new TypeError('Expected title and links');
  if (config.toolsHtml != null && typeof config.toolsHtml !== 'string') throw new TypeError('Expected trusted toolsHtml string');
  const pageLinks = config.links.map(link => `<a class="nr-pagebar-link" href="${escapeHtml(safeUrl(link.href))}">${escapeHtml(link.label)}</a>`).join('');
  const title = escapeHtml(config.title);
  const titleMarkup = config.titleHref ? `<a class="nr-pagebar-title" href="${escapeHtml(safeUrl(config.titleHref))}">${title}</a>` : `<span class="nr-pagebar-title">${title}</span>`;
  const toolsMarkup = config.toolsHtml ? `<div class="nr-pagebar-tools">${config.toolsHtml}</div>` : '';
  const raw = { pageLinks, titleMarkup, toolsMarkup };
  const values = { title: config.title, page: copy[config.lang].page, duplicateTitle: String(config.title === copy[config.lang].page), hasLinks: String(config.links.length > 0) };
  const template = optionalTemplateOverride ?? readFileSync(new URL('./page-navigation.html', import.meta.url), 'utf8');
  return template.replace(/{{(\w+)}}/g, (_, key) => Object.hasOwn(raw, key) ? raw[key] : escapeHtml(values[key] ?? ''));
}
