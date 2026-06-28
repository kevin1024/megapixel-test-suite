/*
 * MegaPixel Test Suite (240p Test Suite for NeXTSTEP)
 * Copyright (C)2011 Artemio Urbina
 * NeXTSTEP port 2026
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
