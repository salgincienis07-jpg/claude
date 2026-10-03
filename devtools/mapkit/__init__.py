"""mapkit - procedural Counter-Strike 1.6 (GoldSrc) map toolkit for Vexmira Zombie.

Modules:
    wad        WAD3 reader/writer, image -> miptex (4 mips, per-texture palette)
    texgen     procedural primitives (tileable noise, voronoi, shading, stroke font)
    textures   original texture library (vx_*), texlights, wad/rad builders
    mapwriter  Valve220 .map writer + brush / entity helpers
    compile    SDHLT CSG/BSP/VIS/RAD pipeline with log parsing
    bspcheck   BSP v30 parser + engine-limit validator
    preview    software renderer (top-down / oblique) for BSPs, contact sheets
"""
__version__ = '1.0'
