#!/usr/bin/python
# -*- coding: utf-8 -*-
"""Wrap a figlet-rendered name and a body of text in a decorative banner.

Used by roles/ssh/tasks/ssh.yml to build /etc/legal.
"""

from __future__ import annotations

_WAVE_MOTIF = "'`'*-._.-*"
# Same motif, rotated to start on the `*` instead of the `'` - used for the
# bottom ribbon so it starts on the same character the top ribbon's `.*`
# leads with, and the two look balanced.
_ROTATED_WAVE_MOTIF = _WAVE_MOTIF[3:] + _WAVE_MOTIF[:3]


def _wave(width, motif=_WAVE_MOTIF):
    """Tile a scalloped-border motif out to exactly `width` characters."""
    if width <= 0:
        return ''
    tiled = motif * (width // len(motif) + 2)
    return tiled[:width]


def frame_text(name_art, body, padding=1):
    """Return a banner: name_art, a rule, then body, all inside a scalloped
    border with a blank padding line around each section.

    Every line is padded to the width of the longest line across both
    sections so the border is a clean rectangle. `padding` is the number of
    spaces between the side borders and the text. The body's first line gets
    two extra leading spaces, matching the original hand-written banner.
    """
    name_lines = name_art.splitlines() or ['']
    body_lines = body.splitlines() or ['']
    if body_lines:
        body_lines[0] = '  ' + body_lines[0]
    content_width = max((len(line) for line in name_lines + body_lines), default=0)
    inner_width = content_width + padding * 2
    outer_width = inner_width + 2

    top = '.*' + _wave(outer_width - 3) + '.'
    bottom = _wave(outer_width, motif=_ROTATED_WAVE_MOTIF)
    rule = '|' + '=' * inner_width + '|'

    def row(text='', center=False):
        text = text.center(content_width) if center else text.ljust(content_width)
        return '|' + (' ' * padding) + text + (' ' * padding) + '|'

    lines = [top, row()]
    lines.extend(row(line, center=True) for line in name_lines)
    lines.append(row())
    lines.append(rule)
    lines.append(row())
    lines.extend(row(line) for line in body_lines)
    lines.append(row())
    lines.append(bottom)

    return '\n'.join(lines)


class FilterModule(object):
    def filters(self):
        return {
            'frame_text': frame_text,
        }
