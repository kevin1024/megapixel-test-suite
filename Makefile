#
# MegaPixel Test Suite - the 240p Test Suite, ported to NeXTSTEP
#
# Plain command-line build for NeXTSTEP 3.3 (Motorola, Intel, or under the
# Previous emulator).
#
#   make        -> the bare executable (launch from a Terminal; quick iteration)
#   make app    -> MegaPixel.app, a double-clickable Workspace application
#   make clean
#
# Workspace runs a bare Unix executable inside a shell; wrapping it in a
# <name>.app directory containing an executable of the same name is what makes
# it launch as a real application (no Terminal window).
#

NAME    = MegaPixel
APP     = $(NAME).app
CC      = cc
CFLAGS  = -O -Wall -Wno-import
OBJS    = main.o AppController.o PatternView.o patterns.o

# AppKit lives in libNeXT_s; the Mach/BSD/Objective-C runtime in libsys_s.
LIBS    = -lNeXT_s -lsys_s

# The Workspace Manager only treats an executable as a launchable GUI
# application (rather than a command-line tool that opens in a shell) if it
# carries an __ICON segment.  We embed the icon TIFF in the "app" section and a
# small header that maps the bundle/executable names to it -- the same layout
# Project Builder produces.
ICON    = $(NAME).tiff
IHDR    = $(NAME).iconheader
ICONSEG = -segcreate __ICON __header $(IHDR) -segcreate __ICON app $(ICON)

.SUFFIXES: .m .o

$(NAME): $(OBJS) $(ICON) $(IHDR)
	$(CC) $(CFLAGS) -o $(NAME) $(OBJS) $(LIBS) $(ICONSEG)

.m.o:
	$(CC) $(CFLAGS) -c $< -o $@

# Application wrapper: a directory <name>.app holding the executable (with the
# icon embedded) plus a copy of the icon TIFF, as the Workspace expects.
app: $(NAME)
	/bin/rm -rf $(APP)
	/bin/mkdir $(APP)
	/bin/cp $(NAME) $(APP)/$(NAME)
	/bin/cp $(ICON) $(APP)/$(NAME).tiff

main.o:         AppController.h
AppController.o: AppController.h PatternView.h patterns.h
PatternView.o:  PatternView.h patterns.h
patterns.o:     patterns.h

clean:
	/bin/rm -rf $(OBJS) $(NAME) $(APP)
