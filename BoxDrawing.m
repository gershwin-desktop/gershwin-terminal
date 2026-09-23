/*
 * Copyright (c) 2026 Simon Peter
 *
 * SPDX-License-Identifier: BSD-2-Clause OR GPL-3.0-or-later
 */

#import "BoxDrawing.h"

#import <AppKit/NSGraphicsContext.h>
#import <AppKit/PSOperators.h>

#import "Defaults.h"

// All geometry is computed in whole device pixels relative to the cell's
// lower left corner, so that strokes are crisp and meet the strokes of the
// neighboring cells exactly.
typedef struct {
  NSGraphicsContext *ctx;
  CGFloat x, y, scale;
  int w, h;
  int light;  // thickness of a light line
} Cell;

enum { NONE = 0, LIGHT = 1, HEAVY = 2, DOUBLE = 3 };

// Weights of the arms from the cell center to its left, right, top and
// bottom edge, two bits each.
#define ARMS(l, r, u, d) ((l) | ((r) << 2) | ((u) << 4) | ((d) << 6))
#define ARM_L(a) ((a) & 3)
#define ARM_R(a) (((a) >> 2) & 3)
#define ARM_U(a) (((a) >> 4) & 3)
#define ARM_D(a) (((a) >> 6) & 3)

// U+2500-257F; the dashed lines, arcs and diagonals are handled separately.
static const unsigned char boxArms[128] = {
    ARMS(1, 1, 0, 0), ARMS(2, 2, 0, 0), ARMS(0, 0, 1, 1), ARMS(0, 0, 2, 2),  // 2500
    ARMS(1, 1, 0, 0), ARMS(2, 2, 0, 0), ARMS(0, 0, 1, 1), ARMS(0, 0, 2, 2),  // 2504
    ARMS(1, 1, 0, 0), ARMS(2, 2, 0, 0), ARMS(0, 0, 1, 1), ARMS(0, 0, 2, 2),  // 2508
    ARMS(0, 1, 0, 1), ARMS(0, 2, 0, 1), ARMS(0, 1, 0, 2), ARMS(0, 2, 0, 2),  // 250C
    ARMS(1, 0, 0, 1), ARMS(2, 0, 0, 1), ARMS(1, 0, 0, 2), ARMS(2, 0, 0, 2),  // 2510
    ARMS(0, 1, 1, 0), ARMS(0, 2, 1, 0), ARMS(0, 1, 2, 0), ARMS(0, 2, 2, 0),  // 2514
    ARMS(1, 0, 1, 0), ARMS(2, 0, 1, 0), ARMS(1, 0, 2, 0), ARMS(2, 0, 2, 0),  // 2518
    ARMS(0, 1, 1, 1), ARMS(0, 2, 1, 1), ARMS(0, 1, 2, 1), ARMS(0, 1, 1, 2),  // 251C
    ARMS(0, 1, 2, 2), ARMS(0, 2, 2, 1), ARMS(0, 2, 1, 2), ARMS(0, 2, 2, 2),  // 2520
    ARMS(1, 0, 1, 1), ARMS(2, 0, 1, 1), ARMS(1, 0, 2, 1), ARMS(1, 0, 1, 2),  // 2524
    ARMS(1, 0, 2, 2), ARMS(2, 0, 2, 1), ARMS(2, 0, 1, 2), ARMS(2, 0, 2, 2),  // 2528
    ARMS(1, 1, 0, 1), ARMS(2, 1, 0, 1), ARMS(1, 2, 0, 1), ARMS(2, 2, 0, 1),  // 252C
    ARMS(1, 1, 0, 2), ARMS(2, 1, 0, 2), ARMS(1, 2, 0, 2), ARMS(2, 2, 0, 2),  // 2530
    ARMS(1, 1, 1, 0), ARMS(2, 1, 1, 0), ARMS(1, 2, 1, 0), ARMS(2, 2, 1, 0),  // 2534
    ARMS(1, 1, 2, 0), ARMS(2, 1, 2, 0), ARMS(1, 2, 2, 0), ARMS(2, 2, 2, 0),  // 2538
    ARMS(1, 1, 1, 1), ARMS(2, 1, 1, 1), ARMS(1, 2, 1, 1), ARMS(2, 2, 1, 1),  // 253C
    ARMS(1, 1, 2, 1), ARMS(1, 1, 1, 2), ARMS(1, 1, 2, 2), ARMS(2, 1, 2, 1),  // 2540
    ARMS(1, 2, 2, 1), ARMS(2, 1, 1, 2), ARMS(1, 2, 1, 2), ARMS(2, 2, 2, 1),  // 2544
    ARMS(2, 2, 1, 2), ARMS(2, 1, 2, 2), ARMS(1, 2, 2, 2), ARMS(2, 2, 2, 2),  // 2548
    ARMS(1, 1, 0, 0), ARMS(2, 2, 0, 0), ARMS(0, 0, 1, 1), ARMS(0, 0, 2, 2),  // 254C
    ARMS(3, 3, 0, 0), ARMS(0, 0, 3, 3), ARMS(0, 3, 0, 1), ARMS(0, 1, 0, 3),  // 2550
    ARMS(0, 3, 0, 3), ARMS(3, 0, 0, 1), ARMS(1, 0, 0, 3), ARMS(3, 0, 0, 3),  // 2554
    ARMS(0, 3, 1, 0), ARMS(0, 1, 3, 0), ARMS(0, 3, 3, 0), ARMS(3, 0, 1, 0),  // 2558
    ARMS(1, 0, 3, 0), ARMS(3, 0, 3, 0), ARMS(0, 3, 1, 1), ARMS(0, 1, 3, 3),  // 255C
    ARMS(0, 3, 3, 3), ARMS(3, 0, 1, 1), ARMS(1, 0, 3, 3), ARMS(3, 0, 3, 3),  // 2560
    ARMS(3, 3, 0, 1), ARMS(1, 1, 0, 3), ARMS(3, 3, 0, 3), ARMS(3, 3, 1, 0),  // 2564
    ARMS(1, 1, 3, 0), ARMS(3, 3, 3, 0), ARMS(3, 3, 1, 1), ARMS(1, 1, 3, 3),  // 2568
    ARMS(3, 3, 3, 3), ARMS(0, 1, 0, 1), ARMS(1, 0, 0, 1), ARMS(1, 0, 1, 0),  // 256C
    ARMS(0, 1, 1, 0), 0, 0, 0,                                               // 2570
    ARMS(1, 0, 0, 0), ARMS(0, 0, 1, 0), ARMS(0, 1, 0, 0), ARMS(0, 0, 0, 1),  // 2574
    ARMS(2, 0, 0, 0), ARMS(0, 0, 2, 0), ARMS(0, 2, 0, 0), ARMS(0, 0, 0, 2),  // 2578
    ARMS(1, 2, 0, 0), ARMS(0, 0, 1, 2), ARMS(2, 1, 0, 0), ARMS(0, 0, 2, 1),  // 257C
};

static void fillPixels(Cell *c, int x, int y, int w, int h)
{
  if (w <= 0 || h <= 0)
    return;
  DPSrectfill(c->ctx, c->x + x / c->scale, c->y + y / c->scale, w / c->scale, h / c->scale);
}

static int thickness(Cell *c, int weight)
{
  return weight == HEAVY ? 2 * c->light : c->light;
}

// Start of a single or heavy stroke centered across a cell length
static int strokeStart(Cell *c, int length, int weight)
{
  return (length - thickness(c, weight)) / 2;
}

static int strokeEnd(Cell *c, int length, int weight)
{
  return strokeStart(c, length, weight) + thickness(c, weight);
}

static void drawArms(Cell *c, unsigned char arms)
{
  int l = ARM_L(arms), r = ARM_R(arms), u = ARM_U(arms), d = ARM_D(arms);
  int t = c->light;
  // Double lines are two light lines with a light line's gap between them,
  // centered where a single line would be.
  int vC = strokeStart(c, c->w, LIGHT), vL = vC - t, vR = vC + t;
  int hC = strokeStart(c, c->h, LIGHT), hB = hC - t, hT = hC + t;
  int start, end;

  // Horizontal single and heavy arms reach across the vertical strokes so
  // that corners are closed; they stop at a double vertical line they meet
  // from one side only.
  if (l == LIGHT || l == HEAVY) {
    if ((u == DOUBLE || d == DOUBLE) && r == NONE) {
      end = (u == DOUBLE && d == DOUBLE) ? vL + t : vR + t;
    } else {
      end = strokeEnd(c, c->w, l);
      if (u == LIGHT || u == HEAVY)
        end = MAX(end, strokeEnd(c, c->w, u));
      if (d == LIGHT || d == HEAVY)
        end = MAX(end, strokeEnd(c, c->w, d));
    }
    fillPixels(c, 0, strokeStart(c, c->h, l), end, thickness(c, l));
  }
  if (r == LIGHT || r == HEAVY) {
    if ((u == DOUBLE || d == DOUBLE) && l == NONE) {
      start = (u == DOUBLE && d == DOUBLE) ? vR : vL;
    } else {
      start = strokeStart(c, c->w, r);
      if (u == LIGHT || u == HEAVY)
        start = MIN(start, strokeStart(c, c->w, u));
      if (d == LIGHT || d == HEAVY)
        start = MIN(start, strokeStart(c, c->w, d));
    }
    fillPixels(c, start, strokeStart(c, c->h, r), c->w - start, thickness(c, r));
  }
  if (d == LIGHT || d == HEAVY) {
    if ((l == DOUBLE || r == DOUBLE) && u == NONE) {
      end = (l == DOUBLE && r == DOUBLE) ? hB + t : hT + t;
    } else {
      end = strokeEnd(c, c->h, d);
      if (l == LIGHT || l == HEAVY)
        end = MAX(end, strokeEnd(c, c->h, l));
      if (r == LIGHT || r == HEAVY)
        end = MAX(end, strokeEnd(c, c->h, r));
    }
    fillPixels(c, strokeStart(c, c->w, d), 0, thickness(c, d), end);
  }
  if (u == LIGHT || u == HEAVY) {
    if ((l == DOUBLE || r == DOUBLE) && d == NONE) {
      start = (l == DOUBLE && r == DOUBLE) ? hT : hB;
    } else {
      start = strokeStart(c, c->h, u);
      if (l == LIGHT || l == HEAVY)
        start = MIN(start, strokeStart(c, c->h, l));
      if (r == LIGHT || r == HEAVY)
        start = MIN(start, strokeStart(c, c->h, r));
    }
    fillPixels(c, strokeStart(c, c->w, u), start, thickness(c, u), c->h - start);
  }

  // Each line of a double arm ends where it meets the perpendicular
  // line(s): the inner line at the near line of a perpendicular double
  // arm, the outer line at the far one, so corners and junctions are open
  // like in ╔ ╦ ╬.
  if (l == DOUBLE) {
    end = (u == DOUBLE) ? vL + t : (u ? strokeEnd(c, c->w, u)
                                      : (d == DOUBLE) ? vR + t : (d ? strokeEnd(c, c->w, d) : vC + t));
    fillPixels(c, 0, hT, end, t);
    end = (d == DOUBLE) ? vL + t : (d ? strokeEnd(c, c->w, d)
                                      : (u == DOUBLE) ? vR + t : (u ? strokeEnd(c, c->w, u) : vC + t));
    fillPixels(c, 0, hB, end, t);
  }
  if (r == DOUBLE) {
    start = (u == DOUBLE) ? vR : (u ? strokeStart(c, c->w, u)
                                    : (d == DOUBLE) ? vL : (d ? strokeStart(c, c->w, d) : vC));
    fillPixels(c, start, hT, c->w - start, t);
    start = (d == DOUBLE) ? vR : (d ? strokeStart(c, c->w, d)
                                    : (u == DOUBLE) ? vL : (u ? strokeStart(c, c->w, u) : vC));
    fillPixels(c, start, hB, c->w - start, t);
  }
  if (d == DOUBLE) {
    end = (l == DOUBLE) ? hB + t : (l ? strokeEnd(c, c->h, l)
                                      : (r == DOUBLE) ? hT + t : (r ? strokeEnd(c, c->h, r) : hC + t));
    fillPixels(c, vL, 0, t, end);
    end = (r == DOUBLE) ? hB + t : (r ? strokeEnd(c, c->h, r)
                                      : (l == DOUBLE) ? hT + t : (l ? strokeEnd(c, c->h, l) : hC + t));
    fillPixels(c, vR, 0, t, end);
  }
  if (u == DOUBLE) {
    start = (l == DOUBLE) ? hT : (l ? strokeStart(c, c->h, l)
                                    : (r == DOUBLE) ? hB : (r ? strokeStart(c, c->h, r) : hC));
    fillPixels(c, vL, start, t, c->h - start);
    start = (r == DOUBLE) ? hT : (r ? strokeStart(c, c->h, r)
                                    : (l == DOUBLE) ? hB : (l ? strokeStart(c, c->h, l) : hC));
    fillPixels(c, vR, start, t, c->h - start);
  }
}

static void drawDashes(Cell *c, unsigned char arms, int count)
{
  BOOL horizontal = ARM_L(arms) != NONE;
  int weight = horizontal ? ARM_L(arms) : ARM_U(arms);
  int length = horizontal ? c->w : c->h;
  // Dashes are centered in equal slots so that they repeat evenly across
  // adjacent cells.
  int gap = MAX(1, length / count / 3);
  int i;

  for (i = 0; i < count; i++) {
    int a = i * length / count + gap / 2;
    int b = (i + 1) * length / count - (gap - gap / 2);

    if (horizontal)
      fillPixels(c, a, strokeStart(c, c->h, weight), b - a, thickness(c, weight));
    else
      fillPixels(c, strokeStart(c, c->w, weight), a, thickness(c, weight), b - a);
  }
}

static void beginStroke(Cell *c)
{
  DPSgsave(c->ctx);
  DPSrectclip(c->ctx, c->x, c->y, c->w / c->scale, c->h / c->scale);
  DPSsetlinewidth(c->ctx, c->light / c->scale);
  DPSnewpath(c->ctx);
}

static void endStroke(Cell *c)
{
  DPSstroke(c->ctx);
  DPSgrestore(c->ctx);
}

// dx, dy: direction of the horizontal and vertical arm (+1 right/up)
static void drawArc(Cell *c, int dx, int dy)
{
  CGFloat s = c->scale;
  CGFloat cx = strokeStart(c, c->w, LIGHT) + c->light / 2.0;
  CGFloat cy = strokeStart(c, c->h, LIGHT) + c->light / 2.0;
  CGFloat r = MIN(c->w, c->h) / 2.0;
  // Control point distance for a bezier quarter circle
  CGFloat k = r * 0.5523;

  beginStroke(c);
  DPSmoveto(c->ctx, c->x + (dx > 0 ? c->w : 0) / s, c->y + cy / s);
  DPSlineto(c->ctx, c->x + (cx + dx * r) / s, c->y + cy / s);
  DPScurveto(c->ctx, c->x + (cx + dx * (r - k)) / s, c->y + cy / s, c->x + cx / s,
             c->y + (cy + dy * (r - k)) / s, c->x + cx / s, c->y + (cy + dy * r) / s);
  DPSlineto(c->ctx, c->x + cx / s, c->y + (dy > 0 ? c->h : 0) / s);
  endStroke(c);
}

// Diagonals are extended beyond the cell (and clipped) so that their ends
// continue into the neighboring cells' diagonals.
static void drawDiagonal(Cell *c, BOOL rising)
{
  CGFloat w = c->w / c->scale, h = c->h / c->scale;

  beginStroke(c);
  if (rising) {
    DPSmoveto(c->ctx, c->x - w, c->y - h);
    DPSlineto(c->ctx, c->x + 2 * w, c->y + 2 * h);
  } else {
    DPSmoveto(c->ctx, c->x - w, c->y + 2 * h);
    DPSlineto(c->ctx, c->x + 2 * w, c->y - h);
  }
  endStroke(c);
}

// Edge of the n-th eighth of a cell length; partial blocks are at least one
// pixel so that they never vanish.
static int eighth(int n, int length)
{
  if (n <= 0)
    return 0;
  if (n >= 8)
    return length;
  return MAX(1, (int)lround(length * n / 8.0));
}

static void drawBlockElement(Cell *c, unichar ch)
{
  // Quadrant bits: upper left, upper right, lower left, lower right
  enum { UL = 1, UR = 2, LL = 4, LR = 8 };
  static const unsigned char quadrants[] = {
      LL, LR, UL, UL | LL | LR, UL | LR, UL | UR | LL, UL | UR | LR, UR, UR | LL, UR | LL | LR};
  int hw = eighth(4, c->w), hh = eighth(4, c->h);

  if (ch == 0x2580) {  // upper half
    fillPixels(c, 0, hh, c->w, c->h - hh);
  } else if (ch >= 0x2581 && ch <= 0x2588) {  // lower eighths, full block
    fillPixels(c, 0, 0, c->w, eighth(ch - 0x2580, c->h));
  } else if (ch >= 0x2589 && ch <= 0x258F) {  // left eighths
    fillPixels(c, 0, 0, eighth(0x2590 - ch, c->w), c->h);
  } else if (ch == 0x2590) {  // right half
    fillPixels(c, hw, 0, c->w - hw, c->h);
  } else if (ch >= 0x2591 && ch <= 0x2593) {  // light, medium, dark shade
    DPSgsave(c->ctx);
    DPSsetalpha(c->ctx, (ch - 0x2590) * 0.25);
    fillPixels(c, 0, 0, c->w, c->h);
    DPSgrestore(c->ctx);
  } else if (ch == 0x2594) {  // upper eighth
    int h = eighth(1, c->h);
    fillPixels(c, 0, c->h - h, c->w, h);
  } else if (ch == 0x2595) {  // right eighth
    int w = eighth(1, c->w);
    fillPixels(c, c->w - w, 0, w, c->h);
  } else {  // quadrants
    unsigned char q = quadrants[ch - 0x2596];

    if (q & UL)
      fillPixels(c, 0, hh, hw, c->h - hh);
    if (q & UR)
      fillPixels(c, hw, hh, c->w - hw, c->h - hh);
    if (q & LL)
      fillPixels(c, 0, 0, hw, hh);
    if (q & LR)
      fillPixels(c, hw, 0, c->w - hw, hh);
  }
}

BOOL TerminalIsBoxDrawingCharacter(unichar c)
{
  return c >= 0x2500 && c <= 0x259F;
}

void TerminalDrawBoxDrawingCharacter(NSGraphicsContext *ctx, unichar ch, NSRect cell)
{
  Cell c;

  c.ctx = ctx;
  c.x = cell.origin.x;
  c.y = cell.origin.y;
  c.scale = [Defaults deviceScaleFactor];
  c.w = (int)lround(cell.size.width * c.scale);
  c.h = (int)lround(cell.size.height * c.scale);
  // Scale the line weight with the font like the glyphs it replaces
  c.light = MAX(1, (int)lround(c.w / 9.0));

  if (ch >= 0x2580) {
    drawBlockElement(&c, ch);
  } else if (ch >= 0x2504 && ch <= 0x250B) {
    drawDashes(&c, boxArms[ch - 0x2500], ch <= 0x2507 ? 3 : 4);
  } else if (ch >= 0x254C && ch <= 0x254F) {
    drawDashes(&c, boxArms[ch - 0x2500], 2);
  } else if (ch >= 0x256D && ch <= 0x2570) {
    static const int arcX[] = {1, -1, -1, 1}, arcY[] = {-1, -1, 1, 1};
    drawArc(&c, arcX[ch - 0x256D], arcY[ch - 0x256D]);
  } else if (ch >= 0x2571 && ch <= 0x2573) {
    if (ch != 0x2572)
      drawDiagonal(&c, YES);
    if (ch != 0x2571)
      drawDiagonal(&c, NO);
  } else {
    drawArms(&c, boxArms[ch - 0x2500]);
  }
}
