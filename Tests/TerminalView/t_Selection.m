/* t_Selection.m - ObjectTesting coverage for TerminalView's text selection.
 *
 * Copyright (c) 2002 Alexander Malmberg <alexander@malmberg.org>
 * Copyright (c) 2015-2017 Sergii Stoian <stoyan255@gmail.com>
 *
 * This file is a part of Terminal.app. Terminal.app is free software; you
 * can redistribute it and/or modify it under the terms of the GNU General
 * Public License as published by the Free Software Foundation; version 2
 * of the License. See COPYING or main.m for more information.
 */

#import <Foundation/Foundation.h>
#import "Testing.h"
#include <fcntl.h>
#include <unistd.h>

/* Unit under test, included in-process so the test can reach the private
   selection/scroll methods and ivars (see gnustep-red-green-tdd skill). */
#include "../../TerminalView.m"

/* Thin accessors onto the ivars the test needs to read/seed. These stay a
   test-only category: TerminalView itself has no reason to expose its
   selection storage or its pty file descriptor to callers. */
@interface TerminalView (SelectionTestAccess)
- (int)test_selectionLength;
- (int)test_screenHeight;
- (void)test_setMasterFD:(int)fd;
- (void)test_putString:(NSString *)s atRow:(int)row column:(int)col;
@end

@implementation TerminalView (SelectionTestAccess)
- (int)test_selectionLength
{
  return selection.length;
}

- (int)test_screenHeight
{
  return screen_height;
}

- (void)test_setMasterFD:(int)fd
{
  master_fd = fd;
}

- (void)test_putString:(NSString *)s atRow:(int)row column:(int)col
{
  int i, len = [s length];
  for (i = 0; i < len; i++) {
    SCREEN(col + i, row).ch = [s characterAtIndex:i];
  }
}
@end

int main(void)
{
  NSAutoreleasePool *arp = [NSAutoreleasePool new];
  Defaults *prefs;

  /* The font backend is initialized lazily by NSApplication's own startup
     path, not by the first font call, so this must run before TerminalView
     touches a font in -initWithFrame:. Run this test under a display (a
     throwaway Xvfb is enough; nothing here draws). */
  [NSApplication sharedApplication];

  prefs = [[Defaults alloc] initEmpty];
  TerminalView *view = [[TerminalView alloc] initWithPreferences:prefs];
  struct selection_range sel;
  int pipefd[2];
  NSString *copied;

  PASS(view != nil, "TerminalView can be constructed headless")

  /* Select "HELLO" on row 0, columns 5..9. */
  [view test_putString:@"HELLO" atRow:0 column:5];
  sel.location = 5;
  sel.length = 5;
  [view _setSelection:sel];
  PASS([view test_selectionLength] == 5, "selection is set before any redraw")

  /* --- new output that does not scroll must not clear the selection --- */
  PASS(pipe(pipefd) == 0, "pipe() stands in for the pty master fd")
  PASS(fcntl(pipefd[0], F_SETFL, O_NONBLOCK) == 0, "read end made non-blocking")
  write(pipefd[1], "x", 1);
  [view test_setMasterFD:pipefd[0]];
  [view readData];
  PASS([view test_selectionLength] == 5,
       "selection survives new pty output that does not scroll the screen")

  copied = [view _selectionAsString];
  PASS_EQUAL(copied, @"HELLO", "Copy would still put the selected text on the pasteboard")

  close(pipefd[0]);
  close(pipefd[1]);

  /* --- a cursor blink tick must not clear the selection --- */
  [view _setSelection:sel];
  [view _blinkCursorTick];
  PASS([view test_selectionLength] == 5, "selection survives a cursor blink tick")

  /* --- a real scroll must still invalidate the selection, since its
     stored range is relative to the current screen top and a scroll
     moves that reference point out from under it. --- */
  [view _setSelection:sel];
  [view ts_scrollUpTop:0 bottom:[view test_screenHeight] rows:1 save:YES];
  PASS([view test_selectionLength] == 0,
       "selection is still cleared when a real scroll invalidates its coordinates")

  RELEASE(view);
  RELEASE(prefs);
  [arp release];
  return 0;
}
