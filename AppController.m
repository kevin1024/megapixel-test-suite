/*
 * MegaPixel Test Suite (240p Test Suite for NeXTSTEP)
 * Copyright (C) 2026 Kevin McCarthy   -- NeXTSTEP port
 * Copyright (C) 2011 Artemio Urbina   -- original 240p Test Suite
 *
 * AppController implementation.
 */

#import "AppController.h"
#import "PatternView.h"
#import "patterns.h"
#import <dpsclient/wraps.h>
#import <dpsclient/dpsclient.h>
#import <stdio.h>

/* NeXTSTEP light-gray panel background. */
#define PANEL_GRAY 0.6667

@implementation AppController

/* Convenience: a non-editable text label inside a panel's content view. */
static id addLabel(id box, const char *s, float x, float y,
                   float w, float h, float size, BOOL bold, int align)
{
    NXRect r;
    id tf;

    NXSetRect(&r, x, y, w, h);
    tf = [[TextField alloc] initFrame:&r];
    [tf setStringValue:s];
    [tf setEditable:NO];
    [tf setSelectable:NO];
    [tf setBezeled:NO];
    [tf setBordered:NO];
    [tf setAlignment:align];
    [tf setBackgroundGray:PANEL_GRAY];
    [tf setFont:[Font newFont:(bold ? "Helvetica-Bold" : "Helvetica")
                         size:size]];
    [box addSubview:tf];
    return tf;
}

- (void)buildMenu
{
    id mainMenu, infoMenu, patternsMenu, viewMenu, windowsMenu, servicesMenu;
    id item, cell;
    int i;

    mainMenu = [[Menu alloc] initTitle:"MegaPixel"];

    /* Info submenu (NeXTSTEP convention: first item of the main menu). */
    item = [mainMenu addItem:"Info" action:(SEL)0 keyEquivalent:0];
    infoMenu = [[Menu alloc] initTitle:"Info"];
    [mainMenu setSubmenu:infoMenu forItem:item];
    cell = [infoMenu addItem:"Info Panel..."
                      action:@selector(showInfoPanel:) keyEquivalent:0];
    [cell setTarget:self];
    [infoMenu sizeToFit];

    /* Patterns submenu, one entry per pattern, tagged with its index. */
    item = [mainMenu addItem:"Patterns" action:(SEL)0 keyEquivalent:0];
    patternsMenu = [[Menu alloc] initTitle:"Patterns"];
    [mainMenu setSubmenu:patternsMenu forItem:item];
    for (i = 0; i < PAT_COUNT; i++) {
        cell = [patternsMenu addItem:kPatternNames[i]
                              action:@selector(selectPattern:)
                       keyEquivalent:0];
        [cell setTarget:self];
        [cell setTag:i];
    }
    [patternsMenu sizeToFit];

    /* View submenu: navigation and full-screen.  Next/Previous/Variant get no
       Command-key equivalent -- their mnemonics n/p/s are hard-reserved for
       New/Print/Save -- so they are driven from the arrow keys instead.  Invert
       and Full Screen use Command-I / Command-F: those are only reserved for
       Italic / Find, which this application does not implement. */
    item = [mainMenu addItem:"View" action:(SEL)0 keyEquivalent:0];
    viewMenu = [[Menu alloc] initTitle:"View"];
    [mainMenu setSubmenu:viewMenu forItem:item];
    cell = [viewMenu addItem:"Next Pattern" action:@selector(nextPattern:)
              keyEquivalent:0];
    [cell setTarget:self];
    cell = [viewMenu addItem:"Previous Pattern" action:@selector(previousPattern:)
              keyEquivalent:0];
    [cell setTarget:self];
    cell = [viewMenu addItem:"Next Variant" action:@selector(nextSub:)
              keyEquivalent:0];
    [cell setTarget:self];
    cell = [viewMenu addItem:"Invert" action:@selector(toggleInvert:)
              keyEquivalent:'i'];
    [cell setTarget:self];
    cell = [viewMenu addItem:"Enter Full Screen" action:@selector(toggleFullscreen:)
              keyEquivalent:'f'];
    [cell setTarget:self];
    [viewMenu sizeToFit];

    /* Windows submenu (standard).  performMiniaturize:/performClose: travel the
       responder chain to the key window; arrangeInFront: is an NXApp command. */
    item = [mainMenu addItem:"Windows" action:(SEL)0 keyEquivalent:0];
    windowsMenu = [[Menu alloc] initTitle:"Windows"];
    [mainMenu setSubmenu:windowsMenu forItem:item];
    [windowsMenu addItem:"Arrange in Front"
                  action:@selector(arrangeInFront:) keyEquivalent:0];
    [windowsMenu addItem:"Miniaturize Window"
                  action:@selector(performMiniaturize:) keyEquivalent:'m'];
    [windowsMenu addItem:"Close Window"
                  action:@selector(performClose:) keyEquivalent:'w'];
    [windowsMenu sizeToFit];
    [NXApp setWindowsMenu:windowsMenu];

    /* Services submenu (standard; populated by the system). */
    item = [mainMenu addItem:"Services" action:(SEL)0 keyEquivalent:0];
    servicesMenu = [[Menu alloc] initTitle:"Services"];
    [mainMenu setSubmenu:servicesMenu forItem:item];
    [NXApp setServicesMenu:servicesMenu];

    /* Standard trailing items; these route up to NXApp. */
    [mainMenu addItem:"Hide" action:@selector(hide:) keyEquivalent:'h'];
    [mainMenu addItem:"Quit" action:@selector(terminate:) keyEquivalent:'q'];

    [mainMenu sizeToFit];
    [NXApp setMainMenu:mainMenu];
}

- setup
{
    NXRect r, cb;
    id box;

    [self buildMenu];

    /* Windowed browsing window.  RESIZEBARSTYLE adds a resize bar so the
       pattern can be scaled; the PatternView is set to track the window size. */
    NXSetRect(&r, 200.0, 200.0, 800.0, 600.0);
    normalWindow = [[Window alloc] initContent:&r
                                         style:NX_RESIZEBARSTYLE
                                       backing:NX_BUFFERED
                                    buttonMask:(NX_CLOSEBUTTONMASK | NX_MINIATURIZEBUTTONMASK)
                                         defer:NO];
    [normalWindow setTitle:"MegaPixel Test Suite"];
    [normalWindow setDelegate:self];

    box = [normalWindow contentView];
    [box setAutoresizeSubviews:YES];
    [box getBounds:&cb];
    view = [[PatternView alloc] initFrame:&cb];
    [view setAutosizing:(NX_WIDTHSIZABLE | NX_HEIGHTSIZABLE)];
    [box addSubview:view];
    [normalWindow makeFirstResponder:view];

    fullscreen = NO;

    /* Defer ordering the window front and the first draw until the run loop
       is up (see -appDidInit:); drawing before then is not flushed to screen. */
    [NXApp setDelegate:self];
    return self;
}

/* Application delegate: the event loop is now running, so the window's
   backing store exists and any drawing we do will actually reach the screen. */
- appDidInit:sender
{
    [NXApp activateSelf:YES];
    [normalWindow makeKeyAndOrderFront:nil];
    [view setPattern:0];
    return self;
}

/* --------------------------------------------------------- full screen */

- enterFullscreen:sender
{
    const NXScreen *scr;
    NXRect fr, b;

    if (fullscreen)
        return self;

    scr = [NXApp colorScreen];
    if (scr == NULL)
        scr = [NXApp mainScreen];
    fr = scr->screenBounds;

    if (fsWindow == nil) {
        fsWindow = [[Window alloc] initContent:&fr
                                         style:NX_PLAINSTYLE
                                       backing:NX_BUFFERED
                                    buttonMask:0
                                         defer:NO];
        [fsWindow setBackgroundGray:0.0];
        [[fsWindow contentView] setAutoresizeSubviews:YES];
    }
    [fsWindow placeWindowAndDisplay:&fr];

    /* Move the one PatternView into the full-screen window and size it to fill. */
    [view removeFromSuperview];
    [[fsWindow contentView] getBounds:&b];
    [view setFrame:&b];
    [[fsWindow contentView] addSubview:view];

    /* Cover the menu while in full screen; it is keyboard-driven from here. */
    [[NXApp mainMenu] orderOut:self];

    [fsWindow makeKeyAndOrderFront:self];
    [fsWindow makeFirstResponder:view];

    /* Raise the window above the application dock (which otherwise draws over
       our right edge): there is no public -setLevel:, so go through the window
       server directly. */
    PSsetwindowlevel(NX_MAINMENULEVEL, [fsWindow windowNum]);
    DPSFlushContext(DPSGetCurrentContext());

    fullscreen = YES;
    [view redraw];
    return self;
}

- exitFullscreen:sender
{
    NXRect b;

    if (!fullscreen)
        return self;

    [view removeFromSuperview];
    [[normalWindow contentView] getBounds:&b];
    [view setFrame:&b];
    [[normalWindow contentView] addSubview:view];

    [fsWindow orderOut:self];
    [[NXApp mainMenu] orderFront:self];
    [normalWindow makeKeyAndOrderFront:self];
    [normalWindow makeFirstResponder:view];
    fullscreen = NO;
    [view redraw];
    return self;
}

- toggleFullscreen:sender
{
    if (fullscreen)
        return [self exitFullscreen:sender];
    return [self enterFullscreen:sender];
}

/* --------------------------------------------------------- info panel */

- showInfoPanel:sender
{
    NXRect pr;
    id box;

    if (infoPanel == nil) {
        NXRect ir;
        id icon;

        NXSetRect(&pr, 300.0, 350.0, 320.0, 232.0);
        infoPanel = [[Panel alloc] initContent:&pr
                                         style:NX_TITLEDSTYLE
                                       backing:NX_BUFFERED
                                    buttonMask:NX_CLOSEBUTTONMASK
                                         defer:NO];
        [infoPanel setTitle:"Info"];
        box = [infoPanel contentView];

        /* Application icon, centred near the top (standard Info-panel layout).
           Use the icon embedded in the __ICON "app" section; only show it if it
           is actually available. */
        {
            id appImage = [NXImage findImageNamed:"app"];
            if (appImage != nil) {
                NXSetRect(&ir, (320.0 - 48.0) / 2.0, 168.0, 48.0, 48.0);
                icon = [[Button alloc] initFrame:&ir];
                [icon setBordered:NO];
                [icon setImage:appImage];
                [box addSubview:icon];
            }
        }

        addLabel(box, "MegaPixel Test Suite", 0.0, 140.0, 320.0, 24.0, 18.0, YES, NX_CENTERED);
        addLabel(box, "Version 1.1",     0.0, 120.0, 320.0, 16.0, 12.0, NO,  NX_CENTERED);
        addLabel(box, "NeXTSTEP display calibration", 0.0, 100.0, 320.0, 16.0, 12.0, NO, NX_CENTERED);
        addLabel(box, "NeXTSTEP port (C) 2026 Kevin McCarthy", 0.0, 78.0, 320.0, 14.0, 10.0, NO, NX_CENTERED);
        addLabel(box, "240p Test Suite (C) Artemio Urbina", 0.0, 54.0, 320.0, 14.0, 10.0, NO, NX_CENTERED);
        addLabel(box, "Left/Right pattern   Up/Down variant",
                 0.0, 32.0, 320.0, 14.0, 10.0, NO, NX_CENTERED);
        addLabel(box, "Cmd-I invert   Cmd-F full screen   Cmd-Q quit",
                 0.0, 16.0, 320.0, 14.0, 10.0, NO, NX_CENTERED);
    }
    [infoPanel makeKeyAndOrderFront:sender];
    [infoPanel display];
    return self;
}

/* --------------------------------------------------------- menu actions */

- setPatternTitle:(int)p sub:(int)s
{
    char title[128];

    if (p < 0 || p >= PAT_COUNT)
        return self;
    sprintf(title, "MegaPixel Test Suite - %s", PatternDisplayName(p, s));
    [normalWindow setTitle:title];
    return self;
}

- selectPattern:sender
{
    /* For a menu command the sender is the matrix, not the clicked cell, so the
       pattern index is on the selected cell's tag. */
    int tag = [sender tag];

    if ([sender respondsTo:@selector(selectedCell)])
        tag = [[sender selectedCell] tag];
    [view setPattern:tag];
    [[view window] makeFirstResponder:view];
    return self;
}

- nextPattern:sender
{
    [view nextPattern];
    return self;
}

- previousPattern:sender
{
    [view previousPattern];
    return self;
}

- nextSub:sender
{
    [view nextSub];
    return self;
}

- toggleInvert:sender
{
    [view toggleInvert];
    return self;
}

/* ------------------------------------------------------ window delegate */

- windowWillClose:sender
{
    if (sender == normalWindow)
        [NXApp terminate:self];
    return self;
}

@end
