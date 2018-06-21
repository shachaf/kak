# Assume programs won't go past the beginning of the tape, and values won't go below 0 or above 255.
# Inputs 0 on EOF.

def bf -params ..1 %{
  eval -no-hooks %{
    exec '%s[^\.,+\-\[\]<lt>>]<ret><a-d>'
    reg 'a' %arg{1}
    exec 'ggiprogram: <esc>"iZ'
    exec 'oinput: <esc>h"apl"rZ'
    exec 'ooctets: <esc>'; insert-octet-table; exec 'ghf ;"mZ'
    exec 'otape: <esc>i¡<esc>h"pZ'
    exec 'ooutput: <esc>j"oZ'

    # Infinite but slow:
    #hook global -group bf NormalIdle .* 'eval -no-hooks bf-insn'
    # Finite but faster:
    forever bf-insn
  }
}

def insert-octet-table %{
  # Taken from Jelly?
  exec 'i'
  exec '¡¢£¤¥¦©¬®µ½¿€ÆÇÐÑ×ØŒÞßæçðıȷñ÷øœþ !"#$%&'''
  exec '()*+,-./0123456789:;<lt>'
  exec '=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~¶'
  exec '°¹²³⁴⁵⁶⁷⁸⁹⁺⁻⁼⁽⁾ƁƇƊƑƓƘⱮƝƤƬƲȤɓƈɗƒɠɦƙɱɲƥʠɼʂƭʋȥ'
  exec 'ẠḄḌẸḤỊḲḶṂṆỌṚṢṬỤṾẈỴẒȦḂĊḊĖḞĠḢİĿṀṄȮṖṘṠṪẆẊẎŻ'
  exec 'ạḅḍẹḥịḳḷṃṇọṛṣṭ§Äẉỵẓȧḃċḋėḟġḣŀṁṅȯṗṙṡṫẇẋẏż«»‘’“”'
  exec '<esc>'
}

def bf-insn %{
  exec '<c-l>'
  exec '"iz'
  try %{ # <
    exec '<a-k>\Q<lt><ret>'
    exec '"pzh"pZ'
  } catch %{ # >
    exec '<a-k>\Q><ret>'
    exec '"pzl'
    try %{
      exec '<a-k>\n<ret>i¡<esc>h'
    }
    exec '"pZ'
  } catch %{ # .
    exec '<a-k>\Q.<ret>'
    exec '"ay'
    exec '"pz"ay"ozgl"ap'
  } catch %{ # [
    exec '<a-k>\Q[<ret>'
    try %{
      exec '"pz'
      exec '<a-k>\A¡\z<ret>'
      exec '"izm;"iZ'
    }
  } catch %{ # ]
    exec '<a-k>\Q]<ret>'
    exec 'mh"iZ'
  } catch %{ # +
    exec '<a-k>\Q+<ret>'
    exec '"pz"ay"mz'
    exec "f%reg{a}" 'l"ay"pz"aR"pZ'
  } catch %{ # -
    exec '<a-k>\Q-<ret>'
    exec '"pz"ay"mz'
    exec "f%reg{a}" 'h"ay"pz"aR"pZ'
  } catch %{ # ,
    exec '<a-k>\Q,<ret>'
    try %{
      exec '"rz'
      exec '<a-k>\n<ret>' # EOF
      exec '"mzl"ay'
    } catch %{
      exec '"rz"ayl"rZ'
    }
    exec '"pz"aR"pZ'
  } catch %{ # EOL
    exec '<a-k>\n<ret>'
    #rmhooks global bf # For IdleHook version above.
    fail 'program halted'
  }
  exec '"izl"iZ'
}

def forever -params 1 %{
  forever_2 "forever_2 %%{forever_2 %arg{1}}"
}

def forever_2 -params 1 %{
  eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}
  eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}
  eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}
  eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}
  eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}
  eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}
  eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}
  eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}
  eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}
  eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}
  eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}
  eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}
  eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}
  eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}; eval %arg{1}
  eval %arg{1}; eval %arg{1}
}
