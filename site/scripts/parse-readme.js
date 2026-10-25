// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Netresearch DTT GmbH
import { isSafeHref } from "./safe-href.js";

/**
 * Tolerant Markdown section extractor.
 *
 * Returns the body (as bullet array or paragraph string) of named ## or ### sections.
 * Section name matching is case-insensitive and ignores leading emoji/punctuation.
 * Missing sections return null — caller decides whether that's an orphan or a fallback.
 */

const SECTION_ALIASES = {
  useCases: [
    "use cases",
    "use case",
    "use when",
    "when to use",
    "when to use this skill",
    "when this skill helps",
    "scenarios",
  ],
  useCasesFallback: [
    "examples",
    "what it does",
    "what this skill does",
    "features",
    "capabilities",
    "key features",
    "quick start",
    "what you can do",
    "common workflows",
  ],
  expectedOutputs: [
    "expected outputs",
    "expected output",
    "outputs",
    "what you get",
    "deliverables",
    "results",
    "output format",
  ],
  // Only sections that state what a project must provide. Installation,
  // setup and dependency sections hold install commands, not context
  // requirements; a README without a requirements section shows none (#132).
  contextRequirements: [
    "context requirements",
    "requirements",
    "prerequisites",
    "context",
    "what this skill needs",
  ],
  relatedSkills: ["related skills", "related", "see also", "companion skills"],
  tags: ["tags", "topics", "keywords"],
};

const HEADING_TRIM_CHARS = new Set([" ", "\t", "#", "*", "_", ">", "•", "➜", "→", "-"]);

function parseHeading(line) {
  let i = 0;
  while (i < line.length && line[i] === "#") i++;
  if (i < 2 || i > 4) return null;
  if (i >= line.length || line[i] !== " " && line[i] !== "\t") return null;
  let j = i;
  while (j < line.length && (line[j] === " " || line[j] === "\t")) j++;
  if (j >= line.length) return null;
  let end = line.length;
  while (end > j && (line[end - 1] === " " || line[end - 1] === "\t")) end--;
  return { level: i, text: line.slice(j, end) };
}

function normalizeHeading(raw) {
  let s = raw.toLowerCase();
  let start = 0;
  let end = s.length;
  while (start < end && HEADING_TRIM_CHARS.has(s[start])) start++;
  while (end > start && HEADING_TRIM_CHARS.has(s[end - 1])) end--;
  s = s.slice(start, end);
  return s.replace(/[^\w\s/]/g, "").trim();
}

function findSection(markdown, aliases) {
  const lines = markdown.split(/\r?\n/);
  const targets = new Set(aliases.map((a) => normalizeHeading(a)));

  let captureLevel = null;
  let captured = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const headingMatch = parseHeading(line);
    if (headingMatch) {
      const level = headingMatch.level;
      const heading = normalizeHeading(headingMatch.text);

      if (captureLevel !== null) {
        if (level <= captureLevel) {
          break;
        }
        // Don't carry sub-section headings into the captured content — the
        // page renders extracted content as plain bullets/paragraphs, and a
        // raw `### Marketplace (Recommended)` line would surface as literal
        // "###" prose.
        continue;
      }

      if (targets.has(heading)) {
        captureLevel = level;
        continue;
      }
    } else if (captureLevel !== null) {
      captured.push(line);
    }
  }

  if (captureLevel === null) return null;
  return captured.join("\n").trim() || null;
}

// README examples are not discovery facts. In particular, a Markdown example
// may itself contain headings and list items that look like our target sections.
function withoutExamples(markdown) {
  let fence = null;
  return markdown.replace(/^[ \t]*<!--[\s\S]*?-->[ \t]*(?:\r?\n|$)/gm, "").split(/\r?\n/).map((line) => {
    const marker = line.match(/^\s*(`{3,}|~{3,})(.*)$/);
    if (fence) {
      if (marker && marker[1][0] === fence[0] && marker[1].length >= fence.length && !marker[2].trim()) {
        fence = null;
      }
      return "";
    }
    if (marker) {
      fence = marker[1];
      return "";
    }
    return line;
  }).join("\n");
}

function parseBullet(line) {
  let i = 0;
  while (i < line.length && (line[i] === " " || line[i] === "\t")) i++;
  if (i >= line.length) return null;
  // Ordered list items ("1. ", "2) ") count as bullets too.
  const ordered = line.slice(i).match(/^\d{1,3}[.)]/);
  if (ordered) i += ordered[0].length - 1;
  else if (line[i] !== "-" && line[i] !== "*" && line[i] !== "+") return null;
  if (i + 1 >= line.length || (line[i + 1] !== " " && line[i + 1] !== "\t")) return null;
  let j = i + 1;
  while (j < line.length && (line[j] === " " || line[j] === "\t")) j++;
  let end = line.length;
  while (end > j && (line[end - 1] === " " || line[end - 1] === "\t")) end--;
  return line.slice(j, end);
}

function bulletItems(block) {
  if (!block) return [];
  const items = [];
  let baseIndent = 0;
  let active = false;
  const tableLines = new Set(tableItems(block).flatMap(({ line, headerLine }) => [headerLine, headerLine + 1, line]));
  for (const [lineNumber, line] of block.split(/\r?\n/).entries()) {
    // Tables are emitted once as normalized rows, including when a Markdown
    // table is indented beneath a list item rather than standing on its own.
    if (tableLines.has(lineNumber)) continue;
    const text = parseBullet(line);
    const indent = line.length - line.trimStart().length;
    if (text !== null) {
      if (!active || indent <= baseIndent) {
        items.push({ text, line: lineNumber });
        baseIndent = indent;
      } else {
        // Arrays are our public metadata shape. Keep nested qualifiers with
        // their parent rather than presenting them as independent use cases.
        const separator = items.at(-1).text.endsWith(":") ? " " : "; ";
        items[items.length - 1].text += separator + text;
      }
      active = true;
    } else if (active && line.trim()) {
      if (indent > baseIndent) items[items.length - 1].text += " " + line.trim();
      else active = false;
    }
  }
  return items;
}

function bulletsFromBlock(block) {
  return bulletItems(block).map(({ text }) => text);
}

function tableCells(line) {
  const cells = [""];
  let codeTicks = 0;
  for (let i = 0; i < line.length; i++) {
    if (line[i] === "\\" && line[i + 1] === "|") {
      cells[cells.length - 1] += "|";
      i++;
    } else if (line[i] === "`") {
      const ticks = line.slice(i).match(/^`+/)[0];
      if (!codeTicks) codeTicks = ticks.length;
      else if (codeTicks === ticks.length) codeTicks = 0;
      cells[cells.length - 1] += ticks;
      i += ticks.length - 1;
    } else if (line[i] === "|" && !codeTicks) {
      cells.push("");
    } else cells[cells.length - 1] += line[i];
  }
  if (!cells[0].trim()) cells.shift();
  if (cells.length && !cells.at(-1).trim()) cells.pop();
  return cells.map((cell) => cell.trim());
}

function tableItems(block) {
  if (!block) return [];
  const lines = block.split(/\r?\n/);
  const items = [];
  for (let i = 0; i < lines.length - 1; i++) {
    const headers = tableCells(lines[i]);
    const separator = tableCells(lines[i + 1]);
    if (headers.length < 2 || separator.length !== headers.length || !separator.every((cell) => /^:?-{3,}:?$/.test(cell))) continue;
    const headerLine = i;
    i += 2;
    for (; i < lines.length; i++) {
      const cells = tableCells(lines[i]);
      if (cells.length !== headers.length) break;
      const values = cells.slice(1).map((cell, col) => headers.length === 2 ? cell : `${headers[col + 1]}: ${cell}`);
      items.push({ text: `${cells[0]}: ${values.join("; ")}`, line: i, headerLine });
    }
    i--;
  }
  return items;
}

function leadParagraph(block) {
  if (!block) return null;
  const paragraphs = block.split(/\r?\n\s*\r?\n/);
  for (const para of paragraphs) {
    const cleaned = para.replace(/\n/g, " ").trim();
    if (!cleaned) continue;
    if (cleaned.startsWith("[!") || cleaned.startsWith("[![")) continue;
    if (cleaned.startsWith("---")) continue;
    if (cleaned.startsWith("|")) continue;
    if (/^[\[\!]/.test(cleaned)) continue;
    if (cleaned.endsWith(":")) {
      // A concrete prerequisite can stand alone after its platform-specific
      // setup block is omitted (Matrix: "For E2EE support ..., install libolm:").
      // Generic lead-ins such as "Run the following:" cannot.
      if (/\b(?:install|requires?|needs?)\s+\S/i.test(cleaned) && !/\b(?:following|below|these|commands?)\s*:$/i.test(cleaned)) return cleaned.slice(0, -1) + ".";
      continue;
    }
    return cleaned;
  }
  return null;
}

function summaryItems(block) {
  const items = [...bulletItems(block), ...tableItems(block)];
  if (items.length) return items.sort((a, b) => a.line - b.line).map(({ text }) => text);
  const paragraph = leadParagraph(block);
  return paragraph ? [paragraph] : [];
}

function stripH1(text) {
  if (!text.startsWith("# ")) return text;
  const newline = text.indexOf("\n");
  return newline === -1 ? "" : text.slice(newline + 1);
}

function extractLinks(block) {
  if (!block) return [];
  const out = [];
  let i = 0;
  while (i < block.length) {
    const open = block.indexOf("[", i);
    if (open === -1) break;
    const close = block.indexOf("]", open + 1);
    if (close === -1) break;
    if (block[close + 1] !== "(") {
      i = close + 1;
      continue;
    }
    const hrefEnd = block.indexOf(")", close + 2);
    if (hrefEnd === -1) break;
    out.push({
      label: block.slice(open + 1, close).trim(),
      href: block.slice(close + 2, hrefEnd).trim(),
    });
    i = hrefEnd + 1;
  }
  return out;
}

export function parseReadme(markdown) {
  if (!markdown || typeof markdown !== "string") {
    return {
      useCases: [],
      expectedOutputs: [],
      contextRequirements: [],
      relatedSkills: [],
      tags: [],
      readmeLead: null,
    };
  }

  markdown = withoutExamples(markdown);
  const useCasesBlock = findSection(markdown, SECTION_ALIASES.useCases)
    ?? findSection(markdown, SECTION_ALIASES.useCasesFallback);
  const expectedOutputsBlock = findSection(markdown, SECTION_ALIASES.expectedOutputs);
  // A dedicated "Context requirements" section takes priority over an earlier
  // generic alias. It is excluded from the second lookup so an empty one cannot
  // hide a later "Requirements" or "Prerequisites" section.
  const contextBlock = findSection(markdown, ["context requirements"])
    ?? findSection(markdown, SECTION_ALIASES.contextRequirements.filter(
      (alias) => alias !== "context requirements",
    ));
  const relatedBlock = findSection(markdown, SECTION_ALIASES.relatedSkills);
  const tagsBlock = findSection(markdown, SECTION_ALIASES.tags);

  const intro = stripH1(markdown.split(/^##\s+/m)[0].trim()).trim();

  return {
    useCases: bulletsFromBlock(useCasesBlock),
    expectedOutputs: summaryItems(expectedOutputsBlock),
    contextRequirements: summaryItems(contextBlock),
    // Related-skill links are rendered as <a href> without further checks,
    // so a target outside the allowlist (e.g. `javascript:`) is dropped here.
    relatedSkills: extractLinks(relatedBlock).filter((l) => isSafeHref(l.href)).map((l) => ({
      label: l.label,
      href: l.href,
      slug: (l.href.match(/netresearch\/([a-z0-9-]+)-skill/) || [])[1] || null,
    })),
    tags: bulletsFromBlock(tagsBlock).length
      ? bulletsFromBlock(tagsBlock)
      : (tagsBlock ? tagsBlock.split(/[,;]/).map((t) => t.trim()).filter(Boolean) : []),
    readmeLead: leadParagraph(intro),
  };
}
