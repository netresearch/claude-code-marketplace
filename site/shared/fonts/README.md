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
# For the display derivative, rename primary name-table records before saving.
# See provenance.json for the exact source and replacement names.
font.flavor = None
font.save(output, reorderTables=False)
```

`provenance.json` records the input/output SHA-256 values, original internal
font names, glyph counts and license checksums. Glyph order, every decomposed
glyph outline, Unicode character mapping and horizontal metrics were compared
after conversion and are unchanged.
The build-only display derivative is named **Netresearch OG Display**, subfamily
`Bold`, and stored as `netresearch-og-display-bold.ttf`. Its primary family,
unique identifier, full name and PostScript name were changed; the original
source names remain documented in `sourceNames` in `provenance.json`. Its Pango
description is `Netresearch OG Display, Bold`.

The source license reserves the name Raleway. Comparing the derivative with the
committed Latin subset establishes unchanged outlines and metrics for that
subset; it does not establish functional equivalence to the copyright holder's
Original Version. The build derivative therefore uses distinct primary names,
following the [OFL FAQ, sections 2.2, 2.8 and 5.3](https://openfontlicense.org/ofl-faq/).

Both fonts retain their original SIL Open Font License 1.1 notices, copied beside
the derived containers as `raleway-OFL.txt` and `open-sans-OFL.txt`. The original
copyright, attribution and license records remain unchanged. No glyph outlines
or metrics were edited, and the canonical public WOFF2 files are unchanged.
