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
    "when to use",
    "when to use this skill",
    "when this skill helps",
    "scenarios",
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
  contextRequirements: [
    "context requirements",
    "requirements",
    "prerequisites",
    "context",
    "what this skill needs",
    "installation",
    "setup",
    "dependencies",
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

function parseBullet(line) {
  let i = 0;
  while (i < line.length && (line[i] === " " || line[i] === "\t")) i++;
  if (i >= line.length) return null;
  if (line[i] !== "-" && line[i] !== "*" && line[i] !== "+") return null;
  if (i + 1 >= line.length || (line[i + 1] !== " " && line[i + 1] !== "\t")) return null;
  let j = i + 1;
  while (j < line.length && (line[j] === " " || line[j] === "\t")) j++;
  let end = line.length;
  while (end > j && (line[end - 1] === " " || line[end - 1] === "\t")) end--;
  return line.slice(j, end);
}

function bulletsFromBlock(block) {
  if (!block) return [];
  return block
    .split(/\r?\n/)
    .map(parseBullet)
    .filter((text) => text !== null)
    .map((text) => text.replace(/`/g, "").trim())
    .filter((text) => text.length > 0);
}

function leadParagraph(block) {
  if (!block) return null;
  const paragraphs = block.split(/\r?\n\s*\r?\n/);
  for (const para of paragraphs) {
    const cleaned = para.replace(/\n/g, " ").trim();
    if (!cleaned) continue;
    if (cleaned.startsWith("[!") || cleaned.startsWith("[![")) continue;
    if (cleaned.startsWith("---")) continue;
    if (/^[\[\!]/.test(cleaned)) continue;
    return cleaned;
  }
  return null;
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

  const useCasesBlock = findSection(markdown, SECTION_ALIASES.useCases);
  const expectedOutputsBlock = findSection(markdown, SECTION_ALIASES.expectedOutputs);
  const contextBlock = findSection(markdown, SECTION_ALIASES.contextRequirements);
  const relatedBlock = findSection(markdown, SECTION_ALIASES.relatedSkills);
  const tagsBlock = findSection(markdown, SECTION_ALIASES.tags);

  const intro = stripH1(markdown.split(/^##\s+/m)[0]).trim();

  return {
    useCases: bulletsFromBlock(useCasesBlock),
    expectedOutputs: bulletsFromBlock(expectedOutputsBlock).length
      ? bulletsFromBlock(expectedOutputsBlock)
      : (leadParagraph(expectedOutputsBlock) ? [leadParagraph(expectedOutputsBlock)] : []),
    contextRequirements: bulletsFromBlock(contextBlock).length
      ? bulletsFromBlock(contextBlock)
      : (leadParagraph(contextBlock) ? [leadParagraph(contextBlock)] : []),
    relatedSkills: extractLinks(relatedBlock).map((l) => ({
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
