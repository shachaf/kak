# TODO: Some keys, e.g. <up>/<down>/<left>, leave the cursor in the wrong position.
# TODO: Escape /[{}:]/ in char_input_ongoing_range_content.
# TODO: In theory this could support completions of more than a single character?
# TODO: Make this work with multiple cursors.
# TODO: Something like emacs's fancy mode that shows completions in a more verbose way.
# TODO: Make this faster (enough to plausibly run on every keystroke).
#       (Note that there's noticeable latency even with a no-op char-input-update.)

decl -docstring "regex pattern matching a character to start automatic completion" \
  str char_input_auto_pattern '[\\^_$\-!?]'

decl -docstring "path of data file for automatic completion" \
  str char_input_auto_data "%val{config}/scripts/char-input-tex.txt"

decl -hidden range-specs char_input_ongoing_range_content
decl -hidden str         char_input_ongoing_replacement
decl -hidden str         char_input_ongoing_hint
decl -hidden str         char_input_ongoing_anchor
decl -hidden str         char_input_ongoing_cursor
decl -hidden str         char_input_ongoing_data

def char-input-begin -params 1..2 \
  -docstring %{
    char-input-begin <file> [<movement>]: Begin char input.
    <file>: Data file for completion.
    [<movement>]: Optional keystrokes to move to the first character of the string to complete.
  } \
  %{
  try %{
    # Fail if completion was already ongoing.
    addhl window group char-input-ongoing
    set window char_input_ongoing_data %arg{1}
    set window char_input_ongoing_range_content ""
    addhl window/char-input-ongoing replace-ranges char_input_ongoing_range_content
    hook -group char-input-ongoing window ModeChange 'insert:normal' char-input-end
    hook -group char-input-ongoing window InsertMove .* char-input-end
    hook -group char-input-ongoing window InsertKey \
      '.|<(minus|plus|space|lt|gt|backspace|tab)>' char-input-complete
    hook -group char-input-ongoing window InsertKey \
      '<([^mpslgbt]|s-.*|(pageup|pagedown|left)>).*' char-input-end
    eval -draft %{
      exec "<esc><space>;%arg{2}"
      set window char_input_ongoing_anchor "%val{cursor_line}.%val{cursor_column}"
    }
    char-input-complete
  } catch %{
    # If completion is already ongoing, see whether running char-input-complete would
    # end it. If so, begin completion after that.
    char-input-complete
    try %{
      addhl window group char-input-ongoing
      rmhl window/char-input-ongoing
      char-input-begin %arg{@}
    }
  }
}

def -hidden char-input-end %{
  try %{
    # Finalize existing completion by replacing the highlighted range with the
    # actual completed text.
    eval -draft -save-regs 'a' %{
      select "%opt{char_input_ongoing_anchor},%opt{char_input_ongoing_cursor}"

      # Don't replace if cursor position ≤ anchor position. Surely there's a
      # better way to do this?
      eval %sh{
        cursor="${kak_selection_desc#*,}"
        ar="${kak_opt_char_input_ongoing_anchor%.*}"
        ac="${kak_opt_char_input_ongoing_anchor#*.}"
        cr="${cursor%.*}"
        cc="${cursor#*.}"
        [ $cr -lt $ar -o \( $cr -eq $ar -a $cc -le $ac \) ] && echo 'fail "early exit"'
      }

      exec H
      reg a %opt{char_input_ongoing_replacement}
      exec '"aR'
    }
  }
  try %{
    rmhl window/char-input-ongoing
    rmhooks window char-input-ongoing
    set window char_input_ongoing_anchor ""
    set window char_input_ongoing_cursor ""
    set window char_input_ongoing_replacement ""
    set window char_input_ongoing_hint ""
    set window char_input_ongoing_range_content ""
    set window char_input_ongoing_data ""
  }
  echo
}

def -hidden char-input-complete %{
  try %{
    eval -draft %{
      exec '<esc>;<space>'
      set window char_input_ongoing_cursor "%val{cursor_line}.%val{cursor_column}"

      # End completion if cursor position (now) < anchor position (when
      # completion started). Surely there's a better way to do this?
      eval %sh{
        ar="${kak_opt_char_input_ongoing_anchor%.*}"
        ac="${kak_opt_char_input_ongoing_anchor#*.}"
        cr="${kak_opt_char_input_ongoing_cursor%.*}"
        cc="${kak_opt_char_input_ongoing_cursor#*.}"
        if [ $cr -lt $ar -o \( $cr -eq $ar -a $cc -lt $ac \) ]; then
          echo 'set window char_input_ongoing_hint ""'
          echo 'fail "early exit"'
        fi
      }

      select "%opt{char_input_ongoing_anchor},%opt{char_input_ongoing_cursor}"
      char-input-update

      try %{
        exec '<a-k>\A..+\z<ret>' 'H'
        set window char_input_ongoing_range_content \
          %val{timestamp} "%val{selection_desc}|{+u}%opt{char_input_ongoing_replacement}"
      } catch %{
        set window char_input_ongoing_range_content ""
      }
    }
  }
  echo -- %opt{char_input_ongoing_hint}
  eval %sh{[ -z "$kak_opt_char_input_ongoing_hint" ] && echo char-input-end}
}

def -hidden char-input-update %{
  eval %sh{ python3 <<'EOF'
#!/usr/bin/env python3
import os

# Format: Each line containing a tab character should be in the form
# "prefix\tchar", where char is either a single code point encoded directly or a
# hexadecimal code point number.

# This would be much more natural with something like a prefix tree, but then
# I'd want to serialize it too and it'd be complicated. Scanning through the
# whole list seems fast enough.

completions = {'': ''}
with open(os.environ['kak_opt_char_input_ongoing_data'], 'r') as f:
  for line in f.readlines():
    if '\t' in line:
      k, v = line.rstrip('\n').rsplit('\t', 1)
      if len(v) != 1:
        v = chr(int(v, base=16))
      completions[k] = v

# The prefix can be empty, but selections are never empty, so we drop the last
# character.
prefix = os.environ['kak_selection'][:-1]

# Figure out the replacement string, which is the prefix with the maximal
# possible completion substituted into it (e.g. \lambdaba -> λba). This always
# succeeds because '' -> '' is in completions.
for i in range(len(prefix),-1,-1):
  preprefix = prefix[:i]
  if preprefix in completions:
    replacement_str = completions[preprefix] + prefix[i:]
    break
print("set window char_input_ongoing_replacement '{}'".format(replacement_str.replace("'", "''")))

# Possible subsequent characters (i.e. children of this node in the prefix tree).
chars = set()
for k in completions.keys():
  if k.startswith(prefix) and len(k) > len(prefix):
    chars.add(k[len(prefix)])

# Show a completion hint, if there are any children.
completion = ''
if chars:
  completion = '{}[{}]'.format(prefix, ''.join(sorted(chars)))
print("set window char_input_ongoing_hint '{}'".format(completion.replace("'", "''")))
EOF
  }
}

def char-input-enable %{
  hook -group char-input window InsertChar %opt{char_input_auto_pattern} \
    %{ char-input-begin %opt{char_input_auto_data} h }
}

def char-input-disable %{
  try char-input-end
  rmhooks window char-input
}

nop 'Configuration' %{
  # Autocomplete:
  set global char_input_auto_pattern '[\\^_$\-!?]'
  set global char_input_auto_data ".../char-input-tex.txt"
  hook global WinCreate .* %{ char-input-enable }
  # Manual complete:
  map global insert <c-k> '<a-;>: char-input-begin ".../char-input-digraph.txt"<ret>'
  map global insert <a-k> '<a-;>: char-input-begin %opt{char_input_auto_data}<ret>'
}
