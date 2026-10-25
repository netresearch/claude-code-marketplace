// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Netresearch DTT GmbH
import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";
import sharp from "sharp";
import { imageCards, renderCard } from "../scripts/generate-og-images.js";

function fontNameRecords(data) {
  for (let i = 0; i < data.readUInt16BE(4); i++) {
    const record = 12 + i * 16;
    if (data.toString("ascii", record, record + 4) !== "name") continue;
    const offset = data.readUInt32BE(record + 8);
    const strings = offset + data.readUInt16BE(offset + 4);
    return Array.from({ length: data.readUInt16BE(offset + 2) }, (_, index) => {
      const name = offset + 6 + index * 12;
      const platform = data.readUInt16BE(name);
      const start = strings + data.readUInt16BE(name + 10);
      const bytes = Buffer.from(data.subarray(start, start + data.readUInt16BE(name + 8)));
      return { id: data.readUInt16BE(name + 6), value: platform === 0 || platform === 3 ? bytes.swap16().toString("utf16le") : bytes.toString("latin1") };
    });
  }
  throw new Error("No OpenType name table found");
}

test("social cards use the supplied catalog count and the correct locale's source metadata", () => {
  const skill = {
    slug: "example", displayName: "Example Tool", descriptionEn: "A source description.",
    descriptionDe: "Eine deutsche Beschreibung.", categoryLabelEn: "Development", categoryLabelDe: "Entwicklung",
  };
  const cards = imageCards([skill, { ...skill, slug: "second" }, { ...skill, slug: "third" }]);
  assert.equal(cards.length, 8);
  assert.match(cards.find((card) => card.filename === "landing.png").title, /3 skill packages/);
  assert.match(cards.find((card) => card.filename === "landing-de.png").title, /3 Skill-Pakete/);
  assert.equal(cards.find((card) => card.filename === "example.png").subtitle, skill.descriptionEn);
  assert.equal(cards.find((card) => card.filename === "example-de.png").subtitle, skill.descriptionDe);
  assert.equal(cards.find((card) => card.filename === "example-de.png").category, "Entwicklung");
  assert.throws(() => imageCards([{ ...skill, descriptionDe: "" }]), /descriptionDe/);
});

test("long German text and literal markup remain inside the image's reserved text areas", async () => {
  const result = await renderCard({
    locale: "de", category: "Entwicklung", title: "<span>SehrLangerZusammengesetzterWerkzeugname</span> ".repeat(20),
    subtitle: "TYPO3, PHP und Dokumentation – mit Ä, Ö, Ü und ß. ".repeat(25),
  });
  const metadata = await sharp(result.png).metadata();
  assert.deepEqual([metadata.format, metadata.width, metadata.height], ["png", 1200, 630]);
  assert.equal(metadata.hasAlpha, true);
  for (const layer of result.layout) {
    assert.ok(layer.width <= layer.maxWidth, layer.name + " width");
    assert.ok(layer.height <= layer.maxHeight, layer.name + " height");
    assert.ok(layer.left + layer.width <= 1200, layer.name + " canvas width");
    assert.ok(layer.top + layer.height <= 630, layer.name + " canvas height");
  }
  const title = result.layout.find((layer) => layer.name === "title");
  const subtitle = result.layout.find((layer) => layer.name === "subtitle");
  assert.match(title.text, /^<span>/);
  assert.match(title.text, /…$/);
  assert.match(subtitle.text, /…$/);
  assert.ok(title.top + title.height < subtitle.top);
  assert.ok(subtitle.top + subtitle.height < 560);
});

test("bundled build fonts retain their recorded bytes and actually replace fallback glyphs", async () => {
  const fontsDirectory = new URL("../shared/fonts/", import.meta.url);
  const provenance = JSON.parse(readFileSync(new URL("provenance.json", fontsDirectory), "utf8"));
  for (const font of provenance.fonts) {
    const data = readFileSync(new URL(font.output, fontsDirectory));
    assert.equal(createHash("sha256").update(data).digest("hex"), font.outputSha256);
    const family = font.names["1"][0];
    const style = font.names["2"][0];
    const fontfile = fileURLToPath(new URL(font.output, fontsDirectory));
    const text = "Netresearch ÄÖÜ 0123";
    const actual = await sharp({ text: { text, font: `${family}, ${style} 60`, fontfile, rgba: true } }).png().toBuffer();
    const fallback = await sharp({ text: { text, font: "Missing-Font-Control 60", rgba: true } }).png().toBuffer();
    assert.notDeepEqual(actual, fallback, font.output + " silently used fallback glyphs");
  }
});

test("the converted display font uses an unreserved primary name while retaining original attribution", () => {
  const fontsDirectory = new URL("../shared/fonts/", import.meta.url);
  const provenance = JSON.parse(readFileSync(new URL("provenance.json", fontsDirectory), "utf8"));
  const display = provenance.fonts.find((font) => font.source.includes("raleway"));
  const records = fontNameRecords(readFileSync(new URL(display.output, fontsDirectory)));
  const primaryIds = new Set([1, 3, 4, 6, 16, 18, 21, 25]);
  assert.ok(records.filter(({ id }) => primaryIds.has(id)).every(({ value }) => !/raleway/i.test(value)));
  assert.ok(records.some(({ id, value }) => id === 1 && value === "Netresearch OG Display"));
  assert.ok(records.some(({ id, value }) => id === 0 && value.includes("The Raleway Project Authors")));
  assert.match(readFileSync(new URL(display.license, fontsDirectory), "utf8"), /Reserved Font Name "Raleway"/);
});
