/*
 * MegaPixel Test Suite (240p Test Suite for NeXTSTEP)
 *
 * PatternView is a custom View (NeXTSTEP 3.x AppKit) that fills itself with the
 * currently selected calibration pattern.  Drawing is delegated to patterns.m.
 */

#import <appkit/View.h>

@interface PatternView : View
{
    int pattern;    /* index into the pattern table (see patterns.h) */
    int sub;        /* sub-variant for patterns that have several    */
    int invert;     /* phase toggle for checkerboard / stripes / pluge */
    int loading;    /* while YES, drawSelf paints the "Loading..." frame */
}

- initFrame:(const NXRect *)frameRect;

- (int)pattern;
- redraw;                   /* force a repaint via the view's window        */
- setPattern:(int)p;        /* selects pattern, resets sub/invert, redraws */
- nextPattern;
- previousPattern;
- nextSub;                  /* advance the sub-variant, wrap around        */
- previousSub;              /* step the sub-variant back, wrap around      */
- toggleInvert;

- drawSelf:(const NXRect *)rects :(int)rectCount;
- (BOOL)acceptsFirstResponder;
- keyDown:(NXEvent *)theEvent;

@end
