/*
 * Copyright (c) 2026 Simon Peter
 *
 * SPDX-License-Identifier: BSD-2-Clause OR GPL-2.0-only
 */

#import "Testing.h"
#import <Foundation/Foundation.h>
#include <unistd.h>

#include "../../FlipSide.m"

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  unsigned long w = 0;

  PASS(FlipSideParseWindowId(@"12345", &w) && w == 12345, "decimal id is parsed");
  PASS(FlipSideParseWindowId(@"12583062", &w) && w == 0xc00096, "id of 0xc00096");
  PASS(!FlipSideParseWindowId(@"0", &w), "zero is rejected");
  PASS(!FlipSideParseWindowId(@"", &w), "empty is rejected");
  PASS(!FlipSideParseWindowId(nil, &w), "nil is rejected");
  PASS(!FlipSideParseWindowId(@"0xc00096", &w), "hex is rejected");
  PASS(!FlipSideParseWindowId(@"12a", &w), "trailing garbage is rejected");
  PASS(!FlipSideParseWindowId(@"-5", &w), "negative is rejected");
  PASS(!FlipSideParseWindowId(@" 5", &w), "whitespace is rejected");
  PASS(!FlipSideParseWindowId(@"999999999999999999999", &w), "overflow is rejected");

  {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *root = [NSTemporaryDirectory() stringByAppendingPathComponent:
        [NSString stringWithFormat:@"t_FlipSide-%d", (int)getpid()]];
    NSString *binA = [root stringByAppendingPathComponent:@"a"];
    NSString *binB = [root stringByAppendingPathComponent:@"b"];
    NSString *path = [NSString stringWithFormat:@"%@:%@", binA, binB];
    NSArray *both = [NSArray arrayWithObjects:@"opencode", @"claude", nil];
    NSArray *swapped = [NSArray arrayWithObjects:@"claude", @"opencode", nil];
    NSData *script = [@"#!/bin/sh\n" dataUsingEncoding:NSASCIIStringEncoding];
    NSDictionary *exec = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0755]
                                                     forKey:NSFilePosixPermissions];
    NSDictionary *plain = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0644]
                                                      forKey:NSFilePosixPermissions];

    [fm createDirectoryAtPath:binA withIntermediateDirectories:YES attributes:nil error:NULL];
    [fm createDirectoryAtPath:binB withIntermediateDirectories:YES attributes:nil error:NULL];

    PASS(FlipSideFirstAvailableCommand(both, path) == nil, "nothing installed gives nil");

    [fm createFileAtPath:[binB stringByAppendingPathComponent:@"claude"] contents:script attributes:exec];
    PASS_EQUAL(FlipSideFirstAvailableCommand(both, path), @"claude",
               "second entry is used when the first is missing");

    [fm createFileAtPath:[binA stringByAppendingPathComponent:@"opencode"] contents:script attributes:exec];
    PASS_EQUAL(FlipSideFirstAvailableCommand(both, path), @"opencode", "first of two available wins");
    PASS_EQUAL(FlipSideFirstAvailableCommand(swapped, path), @"claude", "list order is respected");

    PASS(FlipSideFirstAvailableCommand([NSArray array], path) == nil, "empty array gives nil");
    PASS(FlipSideFirstAvailableCommand(both, nil) == nil, "nil path gives nil");
    PASS(FlipSideFirstAvailableCommand(nil, path) == nil, "nil list gives nil");
    PASS(FlipSideFirstAvailableCommand(both, @"") == nil, "empty path gives nil");

    [fm createFileAtPath:[binA stringByAppendingPathComponent:@"tool"] contents:script attributes:plain];
    PASS(FlipSideFirstAvailableCommand([NSArray arrayWithObject:@"tool"], path) == nil,
         "non-executable file is skipped");

    [fm createDirectoryAtPath:[binA stringByAppendingPathComponent:@"dirtool"]
  withIntermediateDirectories:YES attributes:exec error:NULL];
    PASS(FlipSideFirstAvailableCommand([NSArray arrayWithObject:@"dirtool"], path) == nil,
         "directory named like the command is skipped");

    PASS(FlipSideFirstAvailableCommand([NSArray arrayWithObject:@"/bin/sh"], path) == nil,
         "entry with a slash is rejected");
    PASS(FlipSideFirstAvailableCommand([NSArray arrayWithObject:@"a/opencode"], path) == nil,
         "relative entry with a slash is rejected");
    PASS_EQUAL(FlipSideFirstAvailableCommand(
                   [NSArray arrayWithObjects:@"/bin/sh", @"", [NSNumber numberWithInt:3], @"claude", nil], path),
               @"claude", "invalid entries are skipped, later valid one is used");

    PASS(FlipSideValidCommandName(@"opencode"), "bare name is valid");
    PASS(!FlipSideValidCommandName(@""), "empty name is invalid");
    PASS(!FlipSideValidCommandName(@"a/b"), "name with slash is invalid");
    PASS(!FlipSideValidCommandName((id)[NSNumber numberWithInt:1]), "non-string is invalid");
    PASS(!FlipSideValidCommandName(@"a b"), "name with a space is invalid");

    [fm removeItemAtPath:root error:NULL];
  }

  [pool release];
  return 0;
}
