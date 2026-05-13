#!/usr/bin/env node
/**
 * Build-time OG image generator.
 *
 * Renders one 1200x630 PNG per skill from an SVG template, plus a default
 * landing image. Output goes to site/src/assets/og/ where Eleventy's
 * passthrough copy picks it up — no per-locale duplication needed because
 * skill names + categories are language-neutral identifiers.
 */
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import sharp from "sharp";

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUT_DIR = resolve(__dirname, "../src/assets/og");
mkdirSync(OUT_DIR, { recursive: true });

const skillsModule = await import("../src/_data/skills.js");
const skills = skillsModule.default();

function escapeXml(s) {
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

function wrapText(text, maxCharsPerLine, maxLines) {
  const words = text.split(/\s+/).filter(Boolean);
  const lines = [];
  let line = "";

  for (let i = 0; i < words.length; i++) {
    const word = words[i];
    const candidate = line ? `${line} ${word}` : word;

    if (candidate.length <= maxCharsPerLine) {
      line = candidate;
      continue;
    }

    if (line) lines.push(line);

    if (lines.length === maxLines - 1) {
      lines.push(words.slice(i).join(" "));
      return lines;
    }

    line = word;
  }

  if (line) lines.push(line);
  return lines.slice(0, maxLines);
}

function svgTemplate({ title, subtitle, category }) {
  const titleLines = wrapText(title, 28, 2);
  const subtitleLines = wrapText(subtitle || "", 60, 2);
  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#2F99A4"/>
      <stop offset="1" stop-color="#257880"/>
    </linearGradient>
  </defs>
  <rect width="1200" height="630" fill="url(#bg)"/>
  <rect x="0" y="600" width="1200" height="30" fill="#FF4D00"/>
  <text x="80" y="120" font-family="Helvetica, Arial, sans-serif" font-size="28" font-weight="400" fill="#ffffff" opacity="0.85">netresearch.github.io/claude-code-marketplace</text>
  ${category ? `<text x="80" y="180" font-family="Helvetica, Arial, sans-serif" font-size="24" font-weight="700" fill="#ffffff" letter-spacing="6" text-transform="uppercase">${escapeXml(category.toUpperCase())}</text>` : ""}
  ${titleLines
    .map(
      (line, i) =>
        `<text x="80" y="${300 + i * 90}" font-family="Helvetica, Arial, sans-serif" font-size="84" font-weight="700" fill="#ffffff">${escapeXml(line)}</text>`
    )
    .join("\n  ")}
  ${subtitleLines
    .filter(Boolean)
    .map(
      (line, i) =>
        `<text x="80" y="${510 + i * 36}" font-family="Helvetica, Arial, sans-serif" font-size="28" font-weight="400" fill="#ffffff" opacity="0.9">${escapeXml(line)}</text>`
    )
    .join("\n  ")}
</svg>`;
}

async function renderImage(filename, svg) {
  const png = await sharp(Buffer.from(svg)).png({ compressionLevel: 9 }).toBuffer();
  writeFileSync(resolve(OUT_DIR, filename), png);
}

let count = 0;

// Default landing OG image.
const landingSvg = svgTemplate({
  title: "40 Curated Agent Skills",
  subtitle: "TYPO3, PHP, Go, Docker, security, documentation — for Claude Code, Cursor, Copilot, and 30+ more agents.",
  category: null,
});
await renderImage("landing.png", landingSvg);
count++;

for (const skill of skills) {
  const svg = svgTemplate({
    title: skill.displayName,
    subtitle: skill.description,
    category: skill.categoryLabelEn,
  });
  await renderImage(`${skill.slug}.png`, svg);
  count++;
}

console.log(`Rendered ${count} OG images to ${OUT_DIR}`);
