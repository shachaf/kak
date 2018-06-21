def select-block %{
  eval -itersel -save-regs 'ab' %{
    exec '"aZ<a-x>"by"az'
    eval %sh{
      python3 <<'EOF'
#!/usr/bin/env python3

# Fake block selection.
# Doesn't support tabstop etc.

import os

anchor_str, cursor_str = os.environ['kak_selection_desc'].split(',')
anchor = tuple(int(s) for s in anchor_str.split('.'))
cursor = tuple(int(s) for s in cursor_str.split('.'))

top_row   = min(anchor[0], cursor[0])
bot_row   = max(anchor[0], cursor[0])
left_col  = min(anchor[1], cursor[1])
right_col = max(anchor[1], cursor[1])
downward  = cursor[0] > anchor[0]
rightward = cursor[1] > anchor[1]

selections = []
lines = os.environ['kak_main_reg_b'].split('\n')
for y in range(top_row, bot_row + 1):
  beginning = left_col
  line_cols = len(lines[y-top_row]) + 1 # +1 to include EOL
  if line_cols >= beginning:
    end = min(line_cols, right_col)
    if rightward:
      selections.append(((y, beginning), (y, end)))
    else:
      selections.append(((y, end), (y, beginning)))

if downward:
  selections.reverse() # Only the first selection in the list really matters.

selection_strs = ['{}.{},{}.{}'.format(*a, *c).replace("'", "''")
                  for a, c in selections]
print('select {}'.format(' '.join(selection_strs)))
EOF
    }
    echo
  }
}

nop 'Configuration' %{
  map global normal <c-v> ': select-block<ret>'
}
