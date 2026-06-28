/*
 * MegaPixel Test Suite (240p Test Suite for NeXTSTEP)
 * Copyright (C)2011 Artemio Urbina
 * NeXTSTEP port 2026
 *
 * Procedural pattern drawing.  Most patterns are pure Display PostScript (the
 * PSxxx wraps); the single-pixel patterns also use NXImage / NXDrawBitmap so
 * they can be filled quickly (see drawTiled).
 */

#import <dpsclient/wraps.h>
#import <dpsclient/dpsNeXT.h>   /* NX_COPY and the other compositing ops */
#import <appkit/graphics.h>     /* NXDrawBitmap, NXSetRect */
#import <appkit/NXImage.h>      /* tile caching + fast composite */
#import <stdlib.h>
#import <string.h>
#import <stdio.h>
#import "patterns.h"

const char *kPatternNames[PAT_COUNT] = {
    "SMPTE Color Bars (75%)",
    "Color Fields",
    "PLUGE / Black Level",
    "Grayscale Ramp",
    "Gray Steps",
    "Convergence Grid",
    "Checkerboard",
    "Vertical Stripes",
    "Horizontal Stripes",
    "Circles / Geometry",
    "Sharpness",
    "Overscan Markers"
};

/* ----------------------------------------------------------------- helpers */

static void fillRect(float x, float y, float w, float h, float r, float g, float b)
{
    PSsetrgbcolor(r, g, b);
    PSrectfill(x, y, w, h);
}

static void fillGray(float x, float y, float w, float h, float gray)
{
    PSsetgray(gray);
    PSrectfill(x, y, w, h);
}

static void clearScreen(float w, float h, float gray)
{
    fillGray(0.0, 0.0, w, h, gray);
}

static void label(const char *s, float x, float y, float size, float gray)
{
    PSselectfont("Helvetica", size);
    PSsetgray(gray);
    PSmoveto(x, y);
    PSshow(s);
}

/* --------------------------------------------------------------- patterns */

/* 75% SMPTE/EBU color bars: white, yellow, cyan, green, magenta, red, blue. */
static void drawColorBars(float w, float h)
{
    static const float bars[7][3] = {
        {0.75, 0.75, 0.75},   /* white   */
        {0.75, 0.75, 0.00},   /* yellow  */
        {0.00, 0.75, 0.75},   /* cyan    */
        {0.00, 0.75, 0.00},   /* green   */
        {0.75, 0.00, 0.75},   /* magenta */
        {0.75, 0.00, 0.00},   /* red     */
        {0.00, 0.00, 0.75}    /* blue    */
    };
    float bw = w / 7.0;
    float topY = h * 0.25;          /* leave the lower quarter for refs    */
    float topH = h - topY;
    int i;

    clearScreen(w, h, 0.0);

    for (i = 0; i < 7; i++)
        fillRect(i * bw, topY, bw + 1.0, topH, bars[i][0], bars[i][1], bars[i][2]);

    /* Lower quarter: a 100% white block, a 0% black block and mid grays so
       the white/black points can be judged next to the saturated bars. */
    fillGray(0.0,       0.0, w * 0.25, topY, 1.00);
    fillGray(w * 0.25,  0.0, w * 0.25, topY, 0.00);
    fillGray(w * 0.50,  0.0, w * 0.25, topY, 0.50);
    fillGray(w * 0.75,  0.0, w * 0.25, topY, 0.75);
}

/* Solid full-screen color fields for purity / uniformity checks. */
static void drawColorFields(int sub, float w, float h)
{
    static const float cols[6][3] = {
        {1.0, 0.0, 0.0},   /* red    */
        {0.0, 1.0, 0.0},   /* green  */
        {0.0, 0.0, 1.0},   /* blue   */
        {1.0, 1.0, 1.0},   /* white  */
        {0.0, 0.0, 0.0},   /* black  */
        {0.5, 0.5, 0.5}    /* 50% gray */
    };
    int i = sub % 6;
    fillRect(0.0, 0.0, w, h, cols[i][0], cols[i][1], cols[i][2]);
}

/* PLUGE: a black field with bars just above black plus a 100% reference.
   Adjust display brightness until the near-black bars are just distinct. */
static void drawPluge(int invert, float w, float h)
{
    float base = invert ? 0.04 : 0.00;
    float bw = w / 8.0;

    clearScreen(w, h, base);

    /* Three "just above black" bars at ~4%, ~8%, ~12%. */
    fillGray(bw * 1.0, h * 0.2, bw, h * 0.6, base + 0.04);
    fillGray(bw * 3.0, h * 0.2, bw, h * 0.6, base + 0.08);
    fillGray(bw * 5.0, h * 0.2, bw, h * 0.6, base + 0.12);

    /* 100% white reference on the right. */
    fillGray(bw * 6.5, h * 0.2, bw, h * 0.6, 1.0);

    label("PLUGE - set brightness so the dim bars are just visible",
          bw * 1.0, h * 0.10, 18.0, 0.6);
}

/* Smooth horizontal grayscale ramp, one PostScript fill per pixel column. */
static void drawGrayRamp(float w, float h)
{
    int x, iw = (int)w;
    for (x = 0; x < iw; x++)
        fillGray((float)x, 0.0, 1.0, h, (float)x / w);
}

/* Discrete gray steps.  sub selects 8, 16 or 32 steps. */
static void drawGraySteps(int sub, float w, float h)
{
    int steps = (sub % 3 == 0) ? 8 : (sub % 3 == 1) ? 16 : 32;
    float bw = w / (float)steps;
    int i;
    for (i = 0; i < steps; i++)
        fillGray(i * bw, 0.0, bw + 1.0, h, (float)i / (float)(steps - 1));
}

/* Convergence grid: white lines on black, plus border and centre crosshair. */
static void drawGrid(float w, float h)
{
    float step = 32.0;
    float x, y;

    clearScreen(w, h, 0.0);
    PSsetgray(1.0);
    PSsetlinewidth(1.0);

    for (x = 0.0; x <= w; x += step) {
        PSmoveto(x, 0.0);
        PSlineto(x, h);
    }
    for (y = 0.0; y <= h; y += step) {
        PSmoveto(0.0, y);
        PSlineto(w, y);
    }
    PSstroke();

    /* Brighter border and centre cross. */
    PSsetlinewidth(2.0);
    PSmoveto(1.0, 1.0); PSlineto(w - 1.0, 1.0);
    PSlineto(w - 1.0, h - 1.0); PSlineto(1.0, h - 1.0); PSclosepath();
    PSmoveto(w / 2.0, 0.0); PSlineto(w / 2.0, h);
    PSmoveto(0.0, h / 2.0); PSlineto(w, h / 2.0);
    PSstroke();
}

/* Row helpers for the 1-bit tile built below: bytes per row, and "set pixel x
   white" in a row packed MSB-first. */
#define BPR(iw)            (((iw) + 7) >> 3)
#define SETPX(row, x)      ((row)[(x) >> 3] |= (unsigned char)(0x80 >> ((x) & 7)))

/* Draw a fine repeating pattern (checkerboard or stripes, cell/bar 1px and up).
   Filling every pixel directly is far too slow at full screen, so we render one
   small tile -- a whole number of pattern periods -- into an NXImage, then tile
   the view with fast window-to-window composites: stamp the tile across one
   full-width strip, then stamp that strip down the view.  All offsets are tile
   multiples, so the result is seamless and pixel-exact (1 unit == 1 px). */
static void drawTiled(int isChecker, int vertical, int unit, int invert,
                      float w, float h)
{
    int iw = (int)w, ih = (int)h;
    int period = 2 * unit;                 /* one on+off cycle, in pixels */
    int tile, tbpr, x, y, gx, gy;
    unsigned char *buf, *row0, *row1;
    const unsigned char *planes[5];
    id img;
    NXRect r;
    NXSize sz;
    NXPoint p;

    if (iw <= 0 || ih <= 0 || unit <= 0)
        return;

    /* Tile = a whole number of periods, ~128 px so the grid has few cells. */
    tile = period;
    while (tile < 128)
        tile += period;
    if (tile > iw) tile = iw;
    if (tile > ih) tile = ih;
    tbpr = BPR(tile);

    buf  = (unsigned char *)calloc((unsigned)tbpr * tile, 1);
    row0 = (unsigned char *)calloc((unsigned)tbpr, 1);
    row1 = (unsigned char *)calloc((unsigned)tbpr, 1);
    if (buf == NULL || row0 == NULL || row1 == NULL) {
        free(buf); free(row0); free(row1);
        return;
    }
    if (isChecker) {
        for (x = 0; x < tile; x++) {
            int even = ((x / unit) & 1) == 0;
            if (even != (invert != 0)) SETPX(row0, x);
            if (even == (invert != 0)) SETPX(row1, x);
        }
        for (y = 0; y < tile; y++)
            memcpy(buf + y * tbpr, ((y / unit) & 1) ? row1 : row0, tbpr);
    } else if (vertical) {
        for (x = 0; x < tile; x++)
            if ((((x / unit) & 1) == 0) == (invert == 0)) SETPX(row0, x);
        for (y = 0; y < tile; y++)
            memcpy(buf + y * tbpr, row0, tbpr);
    } else {
        for (y = 0; y < tile; y++)
            memset(buf + y * tbpr,
                   ((((y / unit) & 1) == 0) == (invert == 0)) ? 0xFF : 0x00, tbpr);
    }

    /* Render the tile once into an NXImage cache. */
    sz.width = (float)tile;
    sz.height = (float)tile;
    img = [[NXImage alloc] initSize:&sz];
    [img lockFocus];
    planes[0] = buf;
    planes[1] = planes[2] = planes[3] = planes[4] = NULL;
    NXSetRect(&r, 0.0, 0.0, (float)tile, (float)tile);
    NXDrawBitmap(&r, tile, tile, 1, 1, 1, tbpr, NO, NO,
                 NX_OneIsWhiteColorSpace, planes);
    [img unlockFocus];

    /* Two-level tiling to keep the composite count low: build one full-width
       strip by stamping the tile across it, then stamp the strip down the view.
       That is ~iw/tile + ih/tile composites instead of (iw/tile)*(ih/tile). */
    {
        id strip;
        NXSize ssz;

        ssz.width = (float)iw;
        ssz.height = (float)tile;
        strip = [[NXImage alloc] initSize:&ssz];
        [strip lockFocus];
        for (gx = 0; gx < iw; gx += tile) {
            p.x = (float)gx;
            p.y = 0.0;
            [img composite:NX_COPY toPoint:&p];
        }
        [strip unlockFocus];

        for (gy = 0; gy < ih; gy += tile) {
            p.x = 0.0;
            p.y = (float)gy;
            [strip composite:NX_COPY toPoint:&p];
        }
        [strip free];
    }

    [img free];
    free(buf); free(row0); free(row1);
}

/* Square checkerboard with a selectable cell size in *pixels* (1 = the classic
   single-pixel grid).  "invert" swaps phase. */
static const int kCheckSizes[] = { 1, 2, 8, 32 };
#define NUM_CHECK_SIZES ((int)(sizeof(kCheckSizes) / sizeof(kCheckSizes[0])))

static void drawCheckerboard(int sub, int invert, float w, float h)
{
    drawTiled(1, 0, kCheckSizes[sub % NUM_CHECK_SIZES], invert, w, h);
}

/* Alternating stripes with a selectable bar width in *pixels* (1 = single-pixel
   on/off, the maximum-frequency resolution test). */
static const int kStripeWidths[] = { 1, 2, 3, 4 };
#define NUM_STRIPE_WIDTHS ((int)(sizeof(kStripeWidths) / sizeof(kStripeWidths[0])))

static void drawStripes(int vertical, int sub, int invert, float w, float h)
{
    drawTiled(0, vertical, kStripeWidths[sub % NUM_STRIPE_WIDTHS], invert,
              w, h);
}

/* Geometry / linearity: centred concentric circles over a faint grid plus
   circles in the corners.  On a correctly set up display the circles are
   round and the corner circles are not distorted. */
static void drawCircles(float w, float h)
{
    float cx = w / 2.0, cy = h / 2.0;
    float rmax = (h < w ? h : w) / 2.0 - 4.0;
    float step = 32.0, x, y, r;

    clearScreen(w, h, 0.0);

    /* faint grid */
    PSsetgray(0.25);
    PSsetlinewidth(1.0);
    for (x = 0.0; x <= w; x += step) { PSmoveto(x, 0.0); PSlineto(x, h); }
    for (y = 0.0; y <= h; y += step) { PSmoveto(0.0, y); PSlineto(w, y); }
    PSstroke();

    /* concentric circles */
    PSsetgray(1.0);
    PSsetlinewidth(2.0);
    for (r = step; r <= rmax; r += step) {
        PSnewpath();
        PSarc(cx, cy, r, 0.0, 360.0);
        PSstroke();
    }

    /* corner circles (radius = one grid cell) */
    PSnewpath(); PSarc(0.0, 0.0, step, 0.0, 360.0);
    PSarc(w,   0.0, step, 0.0, 360.0);
    PSarc(0.0, h,   step, 0.0, 360.0);
    PSarc(w,   h,   step, 0.0, 360.0);
    PSstroke();
}

/* Sharpness: blocks of increasingly fine vertical lines (frequency burst). */
static void drawSharpness(float w, float h)
{
    int blocks = 6, b, i;
    float bw = w / (float)blocks;

    clearScreen(w, h, 0.5);
    PSsetgray(0.0);
    for (b = 0; b < blocks; b++) {
        int period = b + 1;              /* 1,2,3.. pixel-pair widths */
        float x0 = b * bw;
        for (i = 0; i < (int)bw; i += period * 2)
            PSrectfill(x0 + i, h * 0.2, (float)period, h * 0.6);
    }
    label("Sharpness: turn enhancement down until edges stop ringing",
          8.0, h * 0.08, 18.0, 0.0);
}

/* Overscan markers: nested rectangles at 2.5/5/10% insets. */
static void drawOverscan(float w, float h)
{
    static const float insets[3] = {0.025, 0.05, 0.10};
    int i;

    clearScreen(w, h, 0.0);
    PSsetgray(1.0);
    PSsetlinewidth(2.0);
    for (i = 0; i < 3; i++) {
        float ix = w * insets[i];
        float iy = h * insets[i];
        PSmoveto(ix, iy);
        PSlineto(w - ix, iy);
        PSlineto(w - ix, h - iy);
        PSlineto(ix, h - iy);
        PSclosepath();
    }
    PSstroke();
    label("Overscan: 2.5% / 5% / 10% insets", 8.0, 8.0, 18.0, 1.0);
}

/* ----------------------------------------------------------------- public */

/* A brief "Loading <name>..." frame, shown the instant a key is pressed (before
   the occasionally slow pattern is drawn) so the keystroke clearly registers. */
void DrawLoadingScreen(const char *name, float w, float h)
{
    char buf[96];
    float size = 28.0;
    float est;

    sprintf(buf, "Loading %s...", name ? name : "");
    fillGray(0.0, 0.0, w, h, 0.20);
    PSselectfont("Helvetica-Bold", size);
    PSsetgray(1.0);
    /* Helvetica-Bold averages a bit over half the point size per character;
       good enough to centre a transient message without a stringwidth round-trip. */
    est = (float)strlen(buf) * size * 0.55;
    PSmoveto((w - est) / 2.0, h / 2.0 - size / 2.0);
    PSshow(buf);
}

int PatternSubCount(int pattern)
{
    switch (pattern) {
        case PAT_COLOR_FIELDS:  return 6;
        case PAT_GRAY_STEPS:    return 3;
        case PAT_CHECKERBOARD:  return NUM_CHECK_SIZES;    /* 1 / 2 / 8 / 32 px */
        case PAT_STRIPES_V:
        case PAT_STRIPES_H:     return NUM_STRIPE_WIDTHS;  /* 1 / 2 / 3 / 4 px  */
        default:                return 1;
    }
}

void DrawPattern(int pattern, int sub, int invert, float w, float h)
{
    switch (pattern) {
        case PAT_SMPTE_BARS:   drawColorBars(w, h);                  break;
        case PAT_COLOR_FIELDS: drawColorFields(sub, w, h);           break;
        case PAT_PLUGE:        drawPluge(invert, w, h);              break;
        case PAT_GRAY_RAMP:    drawGrayRamp(w, h);                   break;
        case PAT_GRAY_STEPS:   drawGraySteps(sub, w, h);             break;
        case PAT_GRID:         drawGrid(w, h);                       break;
        case PAT_CHECKERBOARD: drawCheckerboard(sub, invert, w, h);  break;
        case PAT_STRIPES_V:    drawStripes(1, sub, invert, w, h);    break;
        case PAT_STRIPES_H:    drawStripes(0, sub, invert, w, h);    break;
        case PAT_CIRCLES:      drawCircles(w, h);                    break;
        case PAT_SHARPNESS:    drawSharpness(w, h);                  break;
        case PAT_OVERSCAN:     drawOverscan(w, h);                   break;
        default:               clearScreen(w, h, 0.0);              break;
    }
}
