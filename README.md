MegaPixel Test Suite
===============================================================================

A native NeXTSTEP application -- the 240p Test Suite ported to NeXT -- that
draws display calibration patterns so they can be used to set up a NeXT display
(the 1120x832 MegaPixel mono panel, or a NeXTdimension / NeXTstation Color
framebuffer).  It is named after NeXT's "MegaPixel Display"; "240p" is a console
video mode that does not apply to a NeXT workstation screen.

Unlike the console versions, the patterns are drawn procedurally with Display
PostScript instead of being scaled-up bitmaps, so they stay crisp at the native
resolution of whatever display is attached and adapt to mono or color.

Patterns
-------------------------------------------------------------------------------
  * SMPTE Color Bars (75%)
  * Color Fields        - solid red/green/blue/white/black/gray (Up/Down)
  * PLUGE / Black Level - set brightness so the dim bars are just visible
  * Grayscale Ramp      - smooth 0..100%
  * Gray Steps          - 8 / 16 / 32 discrete steps (Up/Down)
  * Convergence Grid    - lines, border and centre crosshair
  * Checkerboard        - cell 1 / 2 / 8 / 32 px (Up/Down); Cmd-I inverts
  * Vertical Stripes    - bar 1 / 2 / 3 / 4 px (Up/Down); Cmd-I flips phase
  * Horizontal Stripes  - bar 1 / 2 / 3 / 4 px (Up/Down); Cmd-I flips phase
  * Circles / Geometry  - concentric + corner circles over a faint grid
  * Sharpness           - frequency-burst blocks
  * Overscan Markers    - 2.5% / 5% / 10% insets

Controls
-------------------------------------------------------------------------------
  Menu "Patterns"   choose a pattern directly
  Menu "View"       Next / Previous / Variant / Invert / Full Screen
  Menu "Info"       Info panel
  left / right      previous / next pattern
  up / down         next / previous variant
  Command-I         invert / toggle field (checkerboard, stripes, pluge)
  Command-F         toggle full screen (borderless, native resolution)
  esc               leave full screen
  Command-Q         quit

Navigation is on the arrow keys because the mnemonic Command keys (Command-N/P/S
= New/Print/Save) are reserved; Command-I / Command-F are free to use here since
the app implements neither Italic nor Find.

Full-screen mode covers the whole display -- including the application dock --
for chrome-free calibration; it is driven entirely from the keyboard.

Building
-------------------------------------------------------------------------------
Targets NeXTSTEP 3.3 (classic AppKit: View / Window / Menu, the drawSelf::
drawing method, NXEvent, the PSxxx Display PostScript wraps).  Builds cleanly
with the bundled Makefile -- no Project Builder required.

    make            # the bare executable (run from a Terminal: ./MegaPixel)
    make app        # MegaPixel.app, a double-clickable Workspace application
    make clean

`make app` builds the double-clickable wrapper; it also embeds the icon in the
executable's __ICON segment, which is what makes the Workspace launch it as an
application rather than opening it in a shell.

If the link step ever fails, the AppKit shared-library name can differ by
release; the Makefile uses `-lNeXT_s -lsys_s`.

Source layout
-------------------------------------------------------------------------------
  main.m           creates the Application and AppController, runs the loop
  AppController.m  builds the menu, windowed + full-screen windows, Info panel,
                   and routes commands to the view; it is the NXApp delegate
  PatternView.m    custom View; redraws the selected pattern, handles keys
  patterns.m       all pattern drawing (Display PostScript, plus a couple of
                   AppKit C drawing calls for the single-pixel patterns)
  patterns.h       the pattern table; keep kPatternNames[] in sync with it

Pixel accuracy
-------------------------------------------------------------------------------
On a NeXT screen window one PostScript unit maps to exactly one device pixel
(there is no 72-dpi scaling as there is for print), windows are placed at
integer coordinates, and a buffered window composites 1:1 to the screen.  The
PostScript patterns use integer-aligned fills (never stroked lines, which would
straddle pixels), and drawSelf:: floors the view bounds to whole pixels.

The single-pixel patterns must be both exact and fast.  Filling each pixel
directly is far too slow at full screen, so a small tile (a whole number of
pattern periods) is rendered once into an NXImage and the view is tiled with
fast window-to-window composites; because the offsets are tile multiples, the
result is seamless and pixel-exact.

For a true pixel-for-pixel test use Full Screen (Command-F): the pattern fills
the display at native resolution with nothing scaling it in between.  The 1 px
stripes and 1 px checkerboard are the maximum-frequency resolution tests; if
they look like flat gray rather than crisp lines, that is the display/cabling,
not the rendering.

Implementation notes
-------------------------------------------------------------------------------
  * The first draw is done from -appDidInit: (once the run loop is up);
    drawing during setup is not flushed to the screen.
  * Redraws go through `[[self window] display]`.  -[View display] / lockFocus
    silently no-op here because the view reports canDraw=0.
  * -redraw paints a quick "Loading..." frame (and NXPing()s it to the screen)
    before the real pattern, so a keystroke registers immediately.
  * Full screen raises the window above the dock with PSsetwindowlevel(), since
    NeXTSTEP 3.3 has no public -setLevel:.

License
-------------------------------------------------------------------------------
GPL v2 or later -- see COPYING.  This is a NeXTSTEP port of the 240p Test Suite
by Artemio Urbina; the original suite is also GPL.  Display calibration patterns
and concept (C) Artemio Urbina; NeXTSTEP port 2026.
