/*
 * MegaPixel Test Suite (240p Test Suite for NeXTSTEP)
 * Copyright (C)2011 Artemio Urbina
 * NeXTSTEP port 2026
 *
 * This file is part of the 240p Test Suite
 *
 * The 240p Test Suite is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#ifndef PATTERNS_H
#define PATTERNS_H

/*
 * Each pattern is drawn procedurally with Display PostScript so it is crisp
 * at the native resolution of whatever NeXT display is attached (the 1120x832
 * MegaPixel mono panel or a NeXTdimension/Color framebuffer).
 *
 * (w, h) are the pixel dimensions of the view being drawn into.  All drawing
 * happens in the default NeXT coordinate system: origin at the lower-left,
 * +y pointing up.
 *
 * "invert" flips the phase of the toggling patterns (checkerboard / stripes /
 * pluge) so the user can alternate fields the way the console version does.
 * "sub" selects a sub-variant for patterns that have several (the solid color
 * fields, the gray steps, etc.).
 */

/* Keep this list in sync with kPatternNames[] in patterns.m */
enum {
    PAT_SMPTE_BARS = 0,     /* 75% color bars                          */
    PAT_COLOR_FIELDS,       /* solid R/G/B/W/black/gray (use "sub")    */
    PAT_PLUGE,              /* black-level / brightness setup          */
    PAT_GRAY_RAMP,          /* smooth 0..100% horizontal ramp          */
    PAT_GRAY_STEPS,         /* discrete gray steps (use "sub" for N)   */
    PAT_GRID,               /* convergence grid + border + crosshair   */
    PAT_CHECKERBOARD,       /* alternating squares (sub = cell size)    */
    PAT_STRIPES_V,          /* vertical stripes (sub = bar width)       */
    PAT_STRIPES_H,          /* horizontal stripes (sub = bar width)     */
    PAT_CIRCLES,            /* geometry / linearity: circles + grid    */
    PAT_SHARPNESS,          /* fine detail / frequency bursts          */
    PAT_OVERSCAN,           /* nested safe-area markers                */
    PAT_COUNT
};

extern const char *kPatternNames[PAT_COUNT];

/* Number of sub-variants for a given pattern (1 == none). */
int   PatternSubCount(int pattern);

/* Draw one pattern into the current focused view. */
void  DrawPattern(int pattern, int sub, int invert, float w, float h);

/* Draw a brief "Loading <name>..." frame (keystroke-acknowledgement). */
void  DrawLoadingScreen(const char *name, float w, float h);

#endif /* PATTERNS_H */
