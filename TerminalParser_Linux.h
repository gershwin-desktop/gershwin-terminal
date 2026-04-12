/*
  Copyright (c) 2002 Alexander Malmberg <alexander@malmberg.org>
  Copyright (c) 2017 Sergii Stoian <stoyan255@gmail.com>

  This file is a part of Terminal.app. Terminal.app is free software; you
  can redistribute it and/or modify it under the terms of the GNU General
  Public License as published by the Free Software Foundation; version 2
  of the License. See COPYING or main.m for more information.
*/

/* parses escape sequences for 'TERM=linux' */

#ifndef LinuxParser_h
#define LinuxParser_h

#include <iconv.h>

#include "Terminal.h"

@interface TerminalParser_Linux : NSObject <TerminalParser>
{
  id<TerminalScreen> ts;
  int width, height;

  unsigned int tab_stop[8];

  int x, y;

  int top, bottom;

  unsigned int unich;
  int utf_count;

  unsigned char input_buf[16];
  int input_buf_len;

#define TITLE_BUF_SIZE 255
  char title_buf[TITLE_BUF_SIZE + 1];
  unsigned int title_len, title_type;

  enum {
    ESnormal,
    ESesc,
    ESsquare,
    ESgetpars,
    ESgotpars,
    ESfunckey,
    EShash,
    ESsetG0,
    ESsetG1,
    ESpercent,
    ESignore,
    ESnonstd,
    ESpalette,
    EStitle_semi,
    EStitle_buf,
    ESosc_num,
    ESosc_drain,
    ESosc_drain_esc
  } ESstate;
  int vc_state;

  unsigned char decscnm, decom, decawm, deccm, decim;
  unsigned char ques;
  unsigned char priv_intro; /* '>' or '=' private CSI intro, or 0 */
  unsigned char saw_space;  /* seen SP (0x20) intermediate in CSI */
  int osc_num;              /* OSC numeric parameter being collected */
  char osc_buf[256];        /* OSC payload buffer (for OSC 11 ? reply) */
  unsigned int osc_buf_len;
  unsigned char charset, utf, disp_ctrl, toggle_meta;
  unsigned int kbd_flags;
  int G0_charset, G1_charset;

  const unichar *translate;

  unsigned int intensity, underline, reverse, blink;
  unsigned int color, def_color;

  unsigned int fg_rgb, bg_rgb;
  unsigned char rgb_flags;

  /* Alternate screen buffer support. */
  screen_char_t *alt_screen;
  int alt_width, alt_height;
  int alt_saved_x, alt_saved_y;
  BOOL on_alt_screen;

  /* Mouse reporting mode: 0=off, 1000/1002/1003; 1006=SGR encoding flag. */
  int mouse_mode;
  BOOL mouse_sgr;
  BOOL bracketed_paste;
  BOOL focus_events;
#define foreground (color & 0x0f)
#define background (color & 0xf0)

  screen_char_t video_erase_char;

#define NPAR 16
  int npar;
  int par[NPAR];

  int saved_x, saved_y;
  unsigned int s_intensity, s_underline, s_blink, s_reverse, s_charset, s_color;
  int saved_G0, saved_G1;

  iconv_t iconv_state;
  iconv_t iconv_input_state;

  BOOL alternateAsMeta;
  BOOL sendDoubleEscape;
}
@end

#endif
