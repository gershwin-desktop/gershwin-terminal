/*
 * Copyright (c) 2026 Simon Peter
 *
 * SPDX-License-Identifier: BSD-2-Clause OR GPL-2.0-only
 */

#import "FlipSide.h"

NSString *const FlipSideDirectoryDefault = @"FlipSideDirectory";
NSString *const FlipSideParentDefault = @"FlipSideParent";

BOOL FlipSideParseWindowId(NSString *string, unsigned long *windowId)
{
  unsigned long long value = 0;
  NSUInteger i, length = [string length];

  // Digit by digit rather than NSScanner, which accepts signs and whitespace
  // that a window id never has.
  if (length == 0) {
    return NO;
  }
  for (i = 0; i < length; i++) {
    unichar c = [string characterAtIndex:i];

    if (c < '0' || c > '9') {
      return NO;
    }
    value = value * 10 + (c - '0');
    // X11 resource ids are 32 bit; stopping early also avoids overflowing value.
    if (value > 0xFFFFFFFFULL) {
      return NO;
    }
  }
  // 0 is None.
  if (value == 0) {
    return NO;
  }
  *windowId = (unsigned long)value;
  return YES;
}

BOOL FlipSideValidCommandName(id name)
{
  NSUInteger i, length;

  if (![name isKindOfClass:[NSString class]] || [name length] == 0) {
    fprintf(stderr, "Terminal: FlipSideCommands entry is not a non-empty string: %s\n",
            [[name description] UTF8String]);
    return NO;
  }
  length = [name length];
  for (i = 0; i < length; i++) {
    unichar c = [name characterAtIndex:i];

    if (c == '/' || c <= ' ' || c == 0x7f) {
      fprintf(stderr, "Terminal: FlipSideCommands entry must be a bare program name: %s\n",
              [name UTF8String]);
      return NO;
    }
  }
  return YES;
}

NSString *FlipSideFirstAvailableCommand(NSArray *names, NSString *pathVariable)
{
  NSFileManager *fm = [NSFileManager defaultManager];
  NSArray *directories;
  NSUInteger i;

  if (names == nil || pathVariable == nil) {
    return nil;
  }
  directories = [pathVariable componentsSeparatedByString:@":"];
  for (i = 0; i < [names count]; i++) {
    id name = [names objectAtIndex:i];
    NSUInteger d;

    if (!FlipSideValidCommandName(name)) {
      continue;
    }
    for (d = 0; d < [directories count]; d++) {
      NSString *directory = [directories objectAtIndex:d];
      NSString *candidate;
      BOOL isDir = NO;

      // An empty PATH element means the current directory to a shell, which
      // is not a place to start a program from on the user's behalf.
      if ([directory length] == 0) {
        continue;
      }
      candidate = [directory stringByAppendingPathComponent:name];
      if ([fm fileExistsAtPath:candidate isDirectory:&isDir] && !isDir &&
          [fm isExecutableFileAtPath:candidate]) {
        return name;
      }
    }
  }
  return nil;
}
