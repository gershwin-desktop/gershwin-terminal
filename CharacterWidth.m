/*
 * Copyright (c) 2026 Simon Peter
 *
 * SPDX-License-Identifier: BSD-2-Clause OR GPL-3.0-or-later
 */

#include "CharacterWidth.h"

#include <stddef.h>

typedef struct {
  uint32_t first;
  uint32_t last;
} CharacterRange;

#include "CharacterWidthTable.h"

static int isInRanges(uint32_t cp, const CharacterRange *ranges, size_t count)
{
  size_t low = 0, high = count;

  while (low < high) {
    size_t mid = low + (high - low) / 2;

    if (cp < ranges[mid].first) {
      high = mid;
    } else if (cp > ranges[mid].last) {
      low = mid + 1;
    } else {
      return 1;
    }
  }
  return 0;
}

int TerminalCharacterWidth(uint32_t codePoint)
{
  // Fast path for the overwhelmingly common case
  if (codePoint >= 0x20 && codePoint < 0x7F) {
    return 1;
  }
  if (isInRanges(codePoint, zeroWidthRanges, sizeof(zeroWidthRanges) / sizeof(zeroWidthRanges[0]))) {
    return 0;
  }
  if (isInRanges(codePoint, wideRanges, sizeof(wideRanges) / sizeof(wideRanges[0]))) {
    return 2;
  }
  return 1;
}
