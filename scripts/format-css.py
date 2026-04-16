#!/usr/bin/env python3
# Formats CSS rules with hanging-indent value alignment.
# Values within each rule are column-aligned to the longest property name.
# Usage: python3 format-css.py input.css > output.css

# This was written by Claude Code just as a quick-and-dirty way to handle the formatting
# in a repeatable way.  If it starts causing problems or not doing what we want it would
# probably be better to switch to using a purpose-built library for re-writing the CSS
# files.  -Jeremy B April 2026

import re
import sys

DECL_RE = re.compile(r'^-?-?[\w-]+\s*:.+$')

def fail(msg):
    print(f"Error: {msg}", file=sys.stderr)
    sys.exit(1)

INLINE_COMMENT_RE = re.compile(r'/\*.*?\*/', re.DOTALL)

def split_declarations(body):
    """Split on ';' while ignoring semicolons inside url(), quotes, or comments."""
    decls, current, depth, in_quote, i = [], [], 0, None, 0
    while i < len(body):
        ch = body[i]
        if in_quote:
            current.append(ch)
            if ch == in_quote:
                in_quote = None
        elif ch == '/' and body[i:i+2] == '/*':
            end = body.find('*/', i + 2)
            if end == -1:
                fail("unclosed comment")
            current.extend(body[i:end + 2])
            i = end + 1  # +1 because loop will add 1 more
        elif ch in ('"', "'"):
            in_quote = ch
            current.append(ch)
        elif ch == '(':
            depth += 1
            current.append(ch)
        elif ch == ')':
            depth -= 1
            current.append(ch)
        elif ch == ';' and depth == 0:
            decls.append(''.join(current))
            current = []
        else:
            current.append(ch)
        i += 1
    if current:
        decls.append(''.join(current))
    return decls

def format_rule(selector, body):
    # items: ('decl', prop, value, trailing_comment) or ('comment', text)
    items = []

    for chunk in split_declarations(body):
        # Determine if the chunk opens with a trailing comment (same line as
        # previous ';', no newline before the '/*') vs. a standalone comment.
        leading_ws = chunk[:len(chunk) - len(chunk.lstrip())]
        rest       = chunk.lstrip()

        if rest.startswith('/*') and '\n' not in leading_ws:
            end     = rest.find('*/') + 2
            comment = rest[:end].strip()
            rest    = rest[end:]
            if items and items[-1][0] == 'decl':
                items[-1] = (items[-1][0], items[-1][1], items[-1][2], comment)
            else:
                items.append(('comment', comment))

        rest = rest.strip()
        while rest.startswith('/*'):
            end = rest.find('*/') + 2
            items.append(('comment', rest[:end]))
            rest = rest[end:].strip()

        if not rest:
            continue
        clean = INLINE_COMMENT_RE.sub('', rest).strip()
        if not clean:
            continue
        if not DECL_RE.match(clean):
            fail(f"invalid declaration: {clean!r}")
        prop, _, value = clean.partition(':')
        items.append(('decl', prop.strip(), value.strip(), None))

    decl_items = [i for i in items if i[0] == 'decl']
    if not decl_items:
        return f"{selector} {{\n}}"

    max_len = max(len(i[1]) for i in decl_items)
    lines = []
    for item in items:
        if item[0] == 'comment':
            lines.append(f"  {item[1]}")
        else:
            _, prop, value, trailing = item
            line = f"  {prop}:{' ' * (max_len - len(prop) + 1)}{value};"
            if trailing:
                line += f" {trailing}"
            lines.append(line)

    return f"{selector} {{\n" + "\n".join(lines) + "\n}"

def split_preamble(preamble):
    """Return (between, sep, selector): leading /* */ comments, the whitespace
    (newlines only) that originally separated them from the selector, then the selector."""
    comments, rest = [], preamble
    while True:
        stripped = rest.lstrip()
        if not stripped.startswith('/*'):
            break
        rest = stripped
        end = rest.find('*/') + 2
        comments.append(rest[:end].strip())
        rest = rest[end:]
    leading = rest[:len(rest) - len(rest.lstrip())]
    sep = '\n' * leading.count('\n') or '\n'
    return '\n\n'.join(comments), sep, rest.strip()

def top_level_blocks(text):
    """Yield (between, sep, selector, body) for each top-level { } block."""
    i, n, depth, preamble_start, block_start = 0, len(text), 0, 0, None

    while i < n:
        ch = text[i]
        if ch == '{':
            if depth == 0:
                block_start = i
            depth += 1
        elif ch == '}':
            depth -= 1
            if depth < 0:
                fail("unexpected '}'")
            if depth == 0:
                between, sep, selector = split_preamble(text[preamble_start:block_start])
                body = text[block_start + 1:i]
                yield between, sep, selector, body
                preamble_start = i + 1
        i += 1

    if depth != 0:
        fail("unbalanced braces")
    trailing = text[preamble_start:].strip()
    if trailing:
        fail(f"unparsed content: {trailing!r}")

def format_css(text):
    chunks = []
    for between, sep, selector, body in top_level_blocks(text):
        if '{' in body:
            rule = f"{selector} {{{body}}}"
        elif body.strip():
            rule = format_rule(selector, body)
        else:
            rule = f"{selector} {{\n}}"
        chunks.append(f"{between}{sep}{rule}" if between else rule)

    return "\n\n".join(chunks) + "\n"

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <file.css>", file=sys.stderr)
        sys.exit(1)
    try:
        with open(sys.argv[1]) as f:
            text = f.read()
    except OSError as e:
        fail(str(e))
    print(format_css(text), end="")
