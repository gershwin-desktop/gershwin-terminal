/*
 * Copyright (c) 2026 Simon Peter
 *
 * SPDX-License-Identifier: BSD-2-Clause OR GPL-3.0-or-later
 */

#ifndef CharacterWidth_h
#define CharacterWidth_h

#include <stdint.h>

/* Number of terminal cells a code point occupies: 0 for combining marks and
   other zero width characters, 2 for East Asian wide and fullwidth
   characters (including emoji), 1 otherwise. The terminal has to agree with
   wcwidth() in the programs it runs, or their cursor positioning breaks. */
int TerminalCharacterWidth(uint32_t codePoint);

#endif
