/*
 * Copyright (c) 2026 Simon Peter
 *
 * SPDX-License-Identifier: BSD-2-Clause OR GPL-3.0-or-later
 */

#ifndef BoxDrawing_h
#define BoxDrawing_h

#import <Foundation/NSGeometry.h>

@class NSGraphicsContext;

/* Box drawing (U+2500-257F) and block elements (U+2580-259F) are drawn as
   geometry instead of font glyphs: the font's shapes do not match the cell
   exactly, so lines and blocks from adjacent cells (TUI frames, progress
   bars) would show gaps or overlapping, darker joints. */
BOOL TerminalIsBoxDrawingCharacter(unichar c);

/* Draws c with the current color into cell, whose edges must lie on device
   pixels. */
void TerminalDrawBoxDrawingCharacter(NSGraphicsContext *ctx, unichar c, NSRect cell);

#endif
