"""Render the canonical header without external runtime dependencies."""
import html
import json
import re
from pathlib import Path

DIRECTORY = Path(__file__).resolve().parent
DESTINATIONS = {
    'de': {'home': 'https://netresearch.github.io/de/', 'projects': 'https://netresearch.github.io/de/projekte/', 'stack': 'https://netresearch.github.io/modularer-ki-stack-page/', 'impact': 'https://netresearch.github.io/maint/de/'},
    'en': {'home': 'https://netresearch.github.io/', 'projects': 'https://netresearch.github.io/projects/', 'stack': 'https://netresearch.github.io/modularer-ki-stack-page/en/', 'impact': 'https://netresearch.github.io/maint/'},
}

def safe_url(value):
    if not isinstance(value, str) or not value or re.search(r'[\x00-\x20]', value) or value.startswith('//') or (re.match(r'^[a-z][\w+.-]*:', value, re.I) and not re.match(r'^https?:', value, re.I)):
        raise ValueError('Expected a safe URL')
    return value

def render_header(config):
    lang = config.get('lang')
    if lang not in DESTINATIONS:
        raise ValueError('Expected lang de or en')
    if config.get('active') is not None and config['active'] not in DESTINATIONS['en']:
        raise ValueError('Unknown active navigation item')
    text = json.loads((DIRECTORY / 'site-shell.copy.json').read_text(encoding='utf-8'))[lang]
    urls = config.get('languageUrls', {})
    values = {**text, 'assetBase': safe_url(config.get('assetBase')).removesuffix('/'), 'deUrl': safe_url(urls.get('de')), 'enUrl': safe_url(urls.get('en')), 'contactHref': safe_url(config.get('contactHref')), 'deCurrent': 'page' if lang == 'de' else 'false', 'enCurrent': 'page' if lang == 'en' else 'false'}
    links = ''.join(f'<a class="nr-shell-link" href="{html.escape(href, quote=True)}" aria-current="{"page" if key == config.get("active") else "false"}">{html.escape(text[key], quote=True)}</a>' for key, href in DESTINATIONS[lang].items())
    source = (DIRECTORY / 'site-shell.html').read_text(encoding='utf-8')
    return re.sub(r'{{(\w+)}}', lambda match: links if match[1] == 'globalLinks' else html.escape(str(values.get(match[1], '')), quote=True), source)

def render_page_navigation(config):
    """toolsHtml accepts trusted static build markup, never request/user HTML."""
    lang = config.get('lang')
    if lang not in DESTINATIONS:
        raise ValueError('Expected lang de or en')
    if not isinstance(config.get('title'), str) or not config['title'] or not isinstance(config.get('links'), list):
        raise ValueError('Expected title and links')
    if config.get('toolsHtml') is not None and not isinstance(config['toolsHtml'], str):
        raise ValueError('Expected trusted toolsHtml string')
    links = ''.join(f'<a class="nr-pagebar-link" href="{html.escape(safe_url(link["href"]), quote=True)}">{html.escape(str(link["label"]), quote=True)}</a>' for link in config['links'])
    title = html.escape(config['title'], quote=True)
    title_markup = f'<a class="nr-pagebar-title" href="{html.escape(safe_url(config["titleHref"]), quote=True)}">{title}</a>' if config.get('titleHref') else f'<span class="nr-pagebar-title">{title}</span>'
    tools = f'<div class="nr-pagebar-tools">{config["toolsHtml"]}</div>' if config.get('toolsHtml') else ''
    text = json.loads((DIRECTORY / 'site-shell.copy.json').read_text(encoding='utf-8'))[lang]
    values = {'title': config['title'], 'page': text['page'], 'duplicateTitle': str(config['title'] == text['page']).lower(), 'hasLinks': str(bool(config['links'])).lower()}
    raw = {'pageLinks': links, 'titleMarkup': title_markup, 'toolsMarkup': tools}
    source = (DIRECTORY / 'page-navigation.html').read_text(encoding='utf-8')
    return re.sub(r'{{(\w+)}}', lambda match: raw[match[1]] if match[1] in raw else html.escape(str(values.get(match[1], '')), quote=True), source)
