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

function normalizeHeading(raw) {
  return raw
    .toLowerCase()
    .replace(/^[\s#*_>•➜→\-]+/, "")
    .replace(/[\s#*_>•➜→\-]+$/, "")
    .replace(/[^\w\s/]/g, "")
    .trim();
}

function findSection(markdown, aliases) {
  const lines = markdown.split(/\r?\n/);
  const targets = new Set(aliases.map((a) => normalizeHeading(a)));

  let captureLevel = null;
  let captured = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const headingMatch = line.match(/^(#{2,4})\s+(.+?)\s*$/);
    if (headingMatch) {
      const level = headingMatch[1].length;
      const heading = normalizeHeading(headingMatch[2]);

      if (captureLevel !== null) {
        if (level <= captureLevel) {
          break;
        }
        captured.push(line);
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

function bulletsFromBlock(block) {
  if (!block) return [];
  return block
    .split(/\r?\n/)
    .map((line) => line.match(/^\s*[-*+]\s+(.+?)\s*$/))
    .filter(Boolean)
    .map((match) => match[1].replace(/`/g, "").trim())
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

function extractLinks(block) {
  if (!block) return [];
  const matches = [...block.matchAll(/\[([^\]]+)\]\(([^)]+)\)/g)];
  return matches.map((m) => ({ label: m[1].trim(), href: m[2].trim() }));
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

  const intro = markdown
    .split(/^##\s+/m)[0]
    .replace(/^#\s+.+?\r?\n/, "")
    .trim();

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
