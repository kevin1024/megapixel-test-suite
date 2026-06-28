/*
 * MegaPixel Test Suite (240p Test Suite for NeXTSTEP)
 * Copyright (C) 2026 Kevin McCarthy   -- NeXTSTEP port
 * Copyright (C) 2011 Artemio Urbina   -- original 240p Test Suite
 *
 * Entry point.  Creates the Application object (which sets the global NXApp),
 * builds the UI through AppController, and runs the event loop.
 */

#import <appkit/appkit.h>
#import "AppController.h"

void main(int argc, char *argv[])
{
    id controller;

    NXApp = [Application new];

    controller = [[AppController alloc] init];
    [controller setup];

    [NXApp run];
    [NXApp free];
}
