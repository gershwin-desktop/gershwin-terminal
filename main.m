/*
  Copyright (c) 2002, 2003 Alexander Malmberg <alexander@malmberg.org>
  Copyright (c) 2015-2017 Sergii Stoian <stoyan255@gmail.com>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; version 2 of the License.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#import <Foundation/NSDebug.h>

#import <AppKit/NSApplication.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSView.h>

#import "Defaults.h"
#import "TerminalServices.h"
#import "TerminalView.h"
#import "TerminalWindow.h"

@interface Terminal : NSObject

@end

/* TODO */
#import <AppKit/NSWindow.h>
#import <AppKit/NSEvent.h>

@interface NSWindow (avoid_warnings)
- (void)sendEvent:(NSEvent *)e;
@end

@interface TerminalApplication : NSApplication
@end

@implementation TerminalApplication

- (void)sendEvent:(NSEvent *)e
{
  unsigned int flags = [e modifierFlags];

  /*
    If the Alternate/Option key is pressed, synthesize an equivalent event
    with Command pressed and ask the key window and main menu to handle it.
    If a menu matches (e.g., Close Window with 'w'), handle it and return.
    This allows Alt-W to trigger Close Window while keeping Alt-as-Meta
    behavior when no menu equivalent exists.
  */
  if ([e type] == NSKeyDown && (flags & NSAlternateKeyMask)) {
    NSEvent *cmdEvent = [NSEvent keyEventWithType:[e type]
                                         location:[e locationInWindow]
                                    modifierFlags:((flags & ~NSAlternateKeyMask) | NSCommandKeyMask)
                                        timestamp:[e timestamp]
                                     windowNumber:[e windowNumber]
                                          context:[e context]
                                       characters:[e characters]
                     charactersIgnoringModifiers:[e charactersIgnoringModifiers]
                                         isARepeat:[e isARepeat]
                                           keyCode:[e keyCode]];

    if (([[NSApp keyWindow] performKeyEquivalent:cmdEvent]) || ([[NSApp mainMenu] performKeyEquivalent:cmdEvent])) {
      NSDebugLLog(@"key", @"Alt key matched menu key equivalent, handled");
      return;
    }
  }

  /*
    Let NSApplication handle key equivalents when the Command key is pressed,
    or when Alternate-as-Meta is enabled and Alternate is pressed.
  */
  if ([e type] == NSKeyDown &&
      ((flags & NSCommandKeyMask) || ((flags & NSAlternateKeyMask) && [[Defaults shared] alternateAsMeta]))) {
    NSDebugLLog(@"key", @"allowing NSApplication to handle key equivalent");
    [super sendEvent:e];
    return;
  }

  [super sendEvent:e];
}

@end

int main(int argc, const char **argv)
{
  return NSApplicationMain(argc, argv);
}
