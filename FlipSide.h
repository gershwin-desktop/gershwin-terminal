/*
 * Copyright (c) 2026 Simon Peter
 *
 * SPDX-License-Identifier: BSD-2-Clause OR GPL-2.0-only
 */

#import <Foundation/Foundation.h>
#include <sys/types.h>

// The window manager launches Terminal with the user defaults
// FlipSideDirectory and FlipSideParent to show a shell on the back of
// another application's window.
extern NSString *const FlipSideDirectoryDefault;
extern NSString *const FlipSideParentDefault;

// Parses the decimal X11 window id of the parent window. Returns NO for
// anything that is not a plain decimal number above zero.
BOOL FlipSideParseWindowId(NSString *string, unsigned long *windowId);

// YES for a bare program name: a non-empty string without a slash. The name
// is typed into the shell, so whitespace and control characters (which would
// run more than the one program) are refused as well. Logs why to stderr.
BOOL FlipSideValidCommandName(id name);

// Returns the first of names (in order) that is an executable regular file in
// one of the colon separated directories of pathVariable, or nil. Returns the
// name rather than the full path because the shell resolves it. Invalid
// entries are reported on stderr and skipped.
NSString *FlipSideFirstAvailableCommand(NSArray *names, NSString *pathVariable);

// YES when a program other than the shell runs in the foreground of the
// terminal: foregroundGroup (tcgetpgrp of the pty) differs from the shell's
// process group, which is shellPid since the shell leads its own session.
// A foreground group that cannot be read (-1, or 0 for none) or a missing
// shell means no job is known, so closing is not held up for nothing.
BOOL FlipSideHasForegroundJob(pid_t foregroundGroup, pid_t shellPid);
