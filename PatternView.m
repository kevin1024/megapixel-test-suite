/*
 * MegaPixel Test Suite (240p Test Suite for NeXTSTEP)
 * Copyright (C) 2026 Kevin McCarthy   -- NeXTSTEP port
 * Copyright (C) 2011 Artemio Urbina   -- original 240p Test Suite
 *
 * PatternView implementation.
 */

#import "PatternView.h"
#import "AppController.h"
#import "patterns.h"

/* Arrow-key character codes (numeric-pad function keys on the NeXT keyboard;
   the event also carries NX_NUMERICPADMASK in its flags). */
#define KEY_LEFT   172
#define KEY_RIGHT  174
#define KEY_UP     173
#define KEY_DOWN   175

@implementation PatternView

- initFrame:(const NXRect *)frameRect
{
    [super initFrame:frameRect];
    pattern = 0;
    sub = 0;
    invert = 0;
    loading = 0;
    return self;
}

- (int)pattern
{
    return pattern;
}

/* Repaint the view.  Drawing is driven from the window (-[View display] and
   lockFocus do not reliably draw here); flushWindow pushes the buffered backing
   store to the screen even for menu-triggered redraws.  We first paint a quick
   "Loading..." frame and force it out with NXPing -- so a keystroke registers
   immediately even when the pattern is slow -- then draw the pattern over it. */
- redraw
{
    loading = 1;
    [[self window] display];
    [[self window] flushWindow];
    NXPing();

    loading = 0;
    [[self window] display];
    [[self window] flushWindow];
    return self;
}

- setPattern:(int)p
{
    if (p < 0)
        p = PAT_COUNT - 1;
    if (p >= PAT_COUNT)
        p = 0;
    pattern = p;
    sub = 0;
    invert = 0;
    [[NXApp delegate] setPatternTitle:pattern sub:sub];
    [self redraw];
    return self;
}

- nextPattern
{
    return [self setPattern:pattern + 1];
}

- previousPattern
{
    return [self setPattern:pattern - 1];
}

- nextSub
{
    int n = PatternSubCount(pattern);
    if (n > 1) {
        sub = (sub + 1) % n;
        [[NXApp delegate] setPatternTitle:pattern sub:sub];
        [self redraw];
    }
    return self;
}

- previousSub
{
    int n = PatternSubCount(pattern);
    if (n > 1) {
        sub = (sub - 1 + n) % n;
        [[NXApp delegate] setPatternTitle:pattern sub:sub];
        [self redraw];
    }
    return self;
}

- toggleInvert
{
    invert = !invert;
    [self redraw];
    return self;
}

- drawSelf:(const NXRect *)rects :(int)rectCount
{
    NXRect b;

    [self getBounds:&b];
    if (loading) {
        DrawLoadingScreen(PatternDisplayName(pattern, sub),
                          (float)(int)b.size.width, (float)(int)b.size.height);
        return self;
    }
    /* Draw to whole-pixel extents so the single-pixel patterns stay exact. */
    DrawPattern(pattern, sub, invert,
                (float)(int)b.size.width, (float)(int)b.size.height);
    return self;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

/*
 * Keyboard control while a pattern is on screen.  Invert, Full Screen, Quit,
 * etc. are Command-key menu equivalents (Command-I / Command-F / Command-Q);
 * the arrow keys navigate, and Escape leaves full screen.
 *   left / right  -> previous / next pattern
 *   up / down     -> next / previous variant
 *   esc           -> leave full screen
 */
- keyDown:(NXEvent *)theEvent
{
    unsigned short c = theEvent->data.key.charCode;

    switch (c) {
        case KEY_RIGHT:
            [self nextPattern];
            break;
        case KEY_LEFT:
            [self previousPattern];
            break;
        case KEY_UP:
            [self nextSub];
            break;
        case KEY_DOWN:
            [self previousSub];
            break;
        case '\033':                /* escape leaves full screen */
            [[NXApp delegate] exitFullscreen:self];
            break;
        default:
            return [super keyDown:theEvent];
    }
    return self;
}

@end
