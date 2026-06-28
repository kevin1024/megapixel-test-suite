/*
 * MegaPixel Test Suite (240p Test Suite for NeXTSTEP)
 *
 * AppController builds the application menu, the windowed pattern window and a
 * borderless full-screen window, and routes menu / keyboard commands to the
 * PatternView.  It is the NXApp delegate.
 */

#import <appkit/appkit.h>

@interface AppController : Object
{
    id normalWindow;   /* titled window used for browsing with the menu  */
    id fsWindow;       /* borderless window covering the whole screen    */
    id infoPanel;      /* Info panel (lazily created)                    */
    id view;           /* the single PatternView, moved between windows  */
    BOOL fullscreen;   /* YES while the full-screen window is up         */
}

- setup;                    /* build menu + windows, call once at startup */
- appDidInit:sender;        /* app delegate: first draw once run loop is up */

- setPatternTitle:(int)p;   /* reflect the current pattern in the window title */

- selectPattern:sender;     /* menu action; uses [sender tag]            */
- nextPattern:sender;
- previousPattern:sender;
- nextSub:sender;
- toggleInvert:sender;

- toggleFullscreen:sender;  /* enter full screen, or leave it if already in */
- enterFullscreen:sender;
- exitFullscreen:sender;

- showInfoPanel:sender;

@end
