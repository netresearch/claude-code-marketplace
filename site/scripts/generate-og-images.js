#!/usr/bin/env node
// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Netresearch DTT GmbH
/** Build localized 1200x630 social images with bundled brand fonts and logo. */
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import sharp from "sharp";

const HERE = dirname(fileURLToPath(import.meta.url));
const FONT_DIR = resolve(HERE, "../shared/fonts");
const FONTS = {
  heading: { family: "Raleway Thin, Bold", file: resolve(FONT_DIR, "raleway-latin-700-normal.ttf") },
  body: { family: "Open Sans, Regular", file: resolve(FONT_DIR, "open-sans-latin-400-normal.ttf") },
};
const LOGO = resolve(HERE, "../shared/site-shell/netresearch-symbol-only.svg");

function requiredText(value, field) {
  if (typeof value !== "string" || !value.trim()) throw new Error(`OG image requires ${field}`);
  return value;
}

export function imageCards(skills) {
  const cards = [];
  for (const locale of ["en", "de"]) {
    const suffix = locale === "de" ? "-de" : "";
    cards.push({
      filename: `landing${suffix}.png`, locale,
      title: locale === "de" ? `${skills.length} Skill-Pakete` : `${skills.length} skill packages`,
      subtitle: locale === "de"
        ? "TYPO3, PHP, Go, Docker, Sicherheit und Dokumentation."
        : "TYPO3, PHP, Go, Docker, security and documentation.",
      category: "Agent Skills",
    });
    for (const skill of skills) {
      const descriptionField = locale === "de" ? "descriptionDe" : "descriptionEn";
      const categoryField = locale === "de" ? "categoryLabelDe" : "categoryLabelEn";
      cards.push({
        filename: `${skill.slug}${suffix}.png`, locale,
        title: requiredText(skill.displayName, `${skill.slug}.displayName`),
        subtitle: requiredText(skill[descriptionField], `${skill.slug}.${descriptionField}`),
        category: requiredText(skill[categoryField], `${skill.slug}.${categoryField}`),
      });
    }
  }
  return cards;
}

function escapeMarkup(value) {
  return value.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

async function fitText(value, { font, size, minSize = size, width, height, color }) {
  const text = String(value).replace(/[\u0000-\u001f\u007f]/g, " ").replace(/\s+/g, " ").trim();
  async function render(candidate, fontSize) {
    const result = await sharp({ text: {
      text: `<span foreground="${color}">${escapeMarkup(candidate)}</span>`,
      font: `${font.family} ${fontSize}`, fontfile: font.file,
      width, wrap: "word-char", rgba: true, dpi: 72,
    } }).png().toBuffer({ resolveWithObject: true });
    return { png: result.data, text: candidate, size: fontSize, width: result.info.width, height: result.info.height };
  }

  let rendered;
  for (; size >= minSize; size -= 2) {
    rendered = await render(text, size);
    if (rendered.height <= height && rendered.width <= width) return rendered;
  }

  // Measure actual glyph layout rather than guessing a character count. Keep
  // a visible ellipsis when a long source description cannot fit at readable size.
  let low = 0;
  let high = text.length;
  let fitted = await render("…", minSize);
  while (low <= high) {
    const middle = Math.floor((low + high) / 2);
    const candidate = await render(text.slice(0, middle).trimEnd() + "…", minSize);
    if (candidate.height <= height && candidate.width <= width) {
      fitted = candidate;
      low = middle + 1;
    } else high = middle - 1;
  }
  const prefix = fitted.text.slice(0, -1);
  const wordEnd = prefix.lastIndexOf(" ");
  if (wordEnd > 0 && !/\s/.test(text[prefix.length] || "")) {
    fitted = await render(prefix.slice(0, wordEnd) + "…", minSize);
  }
  return fitted;
}

const BACKGROUND = Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630">
  <defs><linearGradient id="petrol" x2="1" y2="1"><stop stop-color="#15585E"/><stop offset="1" stop-color="#0A5057"/></linearGradient></defs>
  <rect width="1200" height="630" fill="url(#petrol)"/>
  <g fill="none" stroke="#B7E2E5" stroke-opacity=".13" stroke-width="2">
    <rect x="1020" y="195" width="350" height="350" rx="18"/>
    <rect x="1052" y="227" width="286" height="286" rx="14"/>
    <rect x="1084" y="259" width="222" height="222" rx="10"/>
  </g>
  <rect x="64" y="44" width="84" height="84" rx="12" fill="#FFF"/>
  <circle cx="69" cy="181" r="5" fill="#FF4D00"/>
  <path d="M64 560H1136" stroke="#FFF" stroke-opacity=".2"/>
</svg>`);
let logo;

export async function renderCard(card) {
  logo ||= sharp(LOGO).resize(84, 84).png().toBuffer();
  const overlays = [{ input: await logo, left: 64, top: 44 }];
  const layout = [];
  async function add(name, text, left, top, maxWidth, maxHeight, font, size, minSize = size, color = "#FFFFFF") {
    const layer = await fitText(text, { font, size, minSize, width: maxWidth, height: maxHeight, color });
    overlays.push({ input: layer.png, left, top });
    layout.push({ name, text: layer.text, left, top, width: layer.width, height: layer.height, maxWidth, maxHeight });
  }
  await add("brand", "Netresearch", 168, 51, 740, 38, FONTS.heading, 30);
  await add("marketplace", "Skills Marketplace", 168, 96, 740, 30, FONTS.body, 22);
  await add("locale", card.locale.toUpperCase(), 1084, 71, 52, 30, FONTS.body, 22);
  await add("category", card.category.toUpperCase(), 88, 167, 856, 30, FONTS.body, 19, 19, "#D8EFF0");
  await add("title", card.title, 64, 218, 880, 176, FONTS.heading, 66, 48);
  await add("subtitle", card.subtitle, 64, 423, 880, 104, FONTS.body, 26, 26, "#E4F2F3");
  await add("address", "netresearch.github.io/claude-code-marketplace", 64, 583, 1040, 25, FONTS.body, 17, 17, "#D8EFF0");
  return { png: await sharp(BACKGROUND).composite(overlays).png({ compressionLevel: 9 }).toBuffer(), layout };
}

async function main() {
  const outDir = resolve(HERE, "../src/assets/og");
  const { default: skillsLoader } = await import("../src/_data/skills.js");
  const cards = imageCards(skillsLoader());
  mkdirSync(outDir, { recursive: true });
  for (const card of cards) {
    const { png } = await renderCard(card);
    writeFileSync(resolve(outDir, card.filename), png);
  }
  console.log(`Rendered ${cards.length} EN/DE OG images to ${outDir}`);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await main();
