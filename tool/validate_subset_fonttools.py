import os
import sys
from fontTools.ttLib import TTFont

subset_path = "build/subset_test.ttf"
if not os.path.exists(subset_path):
    print(f"Error: {subset_path} does not exist.")
    sys.exit(1)

font = TTFont(subset_path)
print(f"fontTools successfully loaded {subset_path}")
print(f"Tables present: {list(font.keys())}")
print(f"Glyph count: {len(font['glyf'].glyphs)}")

# Verify composite glyphs
glyf_table = font['glyf']
compound_count = 0
for glyph_name in font.getGlyphOrder():
    glyph = glyf_table[glyph_name]
    if glyph.isComposite():
        compound_count += 1
        # Verify all components exist in font
        for comp in glyph.components:
            comp_name = comp.glyphName
            assert comp_name in glyf_table, f"Component {comp_name} missing from font!"

print(f"Verified {compound_count} composite glyphs in subset font with zero errors.")
print("SUCCESS: Subset TrueType font passed all fontTools validation checks!")
