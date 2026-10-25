<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
<!-- SPDX-FileCopyrightText: Netresearch DTT GmbH -->

# Build fonts for social images

These TrueType files contain the glyphs from the site's self-hosted WOFF2 files
in `src/assets/fonts/`. Sharp's bundled text renderer silently falls back when
given those WOFF2 files. The generator uses the derived TTF containers instead;
this directory is outside the public asset passthrough.

The one-time conversion used FontTools 4.60.1 and Brotli 1.2.0. Neither is a
build or runtime dependency. The conversion was:

```python
from fontTools.ttLib import TTFont

font = TTFont(source, recalcBBoxes=False, recalcTimestamp=False)
font.flavor = None
font.save(output, reorderTables=False)
```

`provenance.json` records the input/output SHA-256 values, original internal
font names, glyph counts and license checksums. Glyph order, every decomposed
glyph outline, Unicode character mapping and horizontal metrics were compared
after conversion and are unchanged.
The Raleway file's original internal family is `Raleway Thin`, subfamily `Bold`;
the name is preserved. Its Pango description is `Raleway Thin, Bold`.

Both fonts retain their original SIL Open Font License 1.1 notices, copied beside
the derived containers as `raleway-OFL.txt` and `open-sans-OFL.txt`. No glyphs,
internal names or license notices were edited.
