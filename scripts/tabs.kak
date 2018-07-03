# XXX: Spent a little while fixing this post-bbtu but it's still somewhat broken.
# Also note that this script is kind of a joke.
declare-option -hidden int tab_curr
declare-option -hidden str-list tab_bufs
declare-option str tab_mode_text
declare-option bool tabs_enabled false

def tab -params 1.. -shell-candidates %{
  if [ "$kak_token_to_complete" = 0 ]; then
    printf "delete\ndisable\nenable\nlist\nmove\nmode\nmove-left\nmove-right\nnew\nnext\nprev\n"
  fi
} \
  %{ eval %sh{
bash -s -- "$@" <<'EOF'
  join_arr() {
    local IFS="$1"; shift
    echo "$*"
  }

  tab_new() {
    tab_bufs+=("$kak_bufname")
    tab_switch "${#tab_bufs[@]}"
    [[ $# != 0 ]] && echo "$@"
  }

  tab_switch() {
    local tab_id="$1"
    if [[ "$tab_id" -gt "${#tab_bufs[@]}" ]]; then
      echo "echo 'no such tab'"
      exit
    fi
    tab_curr="$tab_id"
    echo "try %{ buffer ${tab_bufs[tab_curr-1]} } catch %{ echo 'buffer gone!'; buffer '*debug*' }"
    update_tab_state
  }

  tab_next() { tab_switch "$(((tab_curr % ${#tab_bufs[@]}) + 1))"; }
  tab_prev() { tab_switch "$((((tab_curr + ${#tab_bufs[@]} - 2) % ${#tab_bufs[@]}) + 1))"; }

  tab_delete() {
    local tab_id="${1:-$tab_curr}"
    unset tab_bufs[$((tab_id-1))]
    tab_bufs=(${tab_bufs[@]})
    if [[ "$tab_curr" -le $((tab_id)) ]]; then
      tab_curr="$((tab_curr - 1))"
      [[ "$tab_curr" == "0" ]] && tab_curr=1
    fi
    if [[ "${#tab_bufs[@]}" == 0 ]]; then
      tabs_disable
    else
      tab_switch "$tab_curr"
    fi
  }

  tab_buf_deleted() {
    local bufname="$1"
    for i in $(seq "${#tab_bufs[@]}" 1); do
      if [[ "${tab_bufs[i]}" == "$bufname" ]]; then
        tab_delete "$i"
        # Might just want to leave it?
        # Maybe just replace it with a placeholder (which is what happens anyway)?
      fi
    done
  }

  tab_move() {
    local pos="$1"
    if ! [[ $pos -gt 0 && $pos -le "${#tab_bufs[@]}" ]]; then
      echo "fail 'invalid target'"
      exit
    fi
    local tab_id="$tab_curr" # $2?
    local tab_buf=${tab_bufs[$((tab_id))-1]}
    local tab_bufs_without_tab=(${tab_bufs[@]})
    unset tab_bufs_without_tab[$((tab_id-1))]; tab_bufs_without_tab=(${tab_bufs_without_tab[@]})
    tab_bufs=()
    tab_bufs+=(${tab_bufs_without_tab[@]::$((pos-1))})
    tab_bufs+=($tab_buf)
    tab_bufs+=(${tab_bufs_without_tab[@]:$((pos-1)):$(("${#tab_bufs_without_tab[@]}" - pos + 1))})
    tab_switch $((pos))
  }

  tab_move_left()  { [[ "$tab_curr" -gt 1 ]]                  && tab_move "$((tab_curr-1))"; }
  tab_move_right() { [[ "$tab_curr" -le "${#tab_bufs[@]}" ]]  && tab_move "$((tab_curr+1))"; }

  tab_list() {
    tablist=''
    for i in "${!tab_bufs[@]}"; do
      char=' '
      [[ $i == $tab_curr ]] && char='*'
      tablist="$tablist$char$i - ${tab_bufs[i]}"$'\n'
    done
    echo "info -title tabs -- %:${tablist}:"
  }

  # triggered by buffer hook
  tab_change_buffer() {
    tab_bufs[$((tab_curr - 1))]="$1"
    update_tab_state
  }


  update_tab_state() {
    if [[ "$tabs_enabled" == false ]]; then
      echo "set global tab_mode_text ''"
      return
    fi

    echo "set global tab_bufs $(join_arr ' ' ${tab_bufs[@]})"
    echo "set global tab_curr $tab_curr"

    local tab_text
    for i in $(seq "${#tab_bufs[@]}"); do
      tab_text="$i"
      [[ "$i" == "$tab_curr" ]] && tab_text="[$i]"
      tab_mode_text="$tab_mode_text$tab_text"
    done
    echo "set global tab_mode_text '$tab_mode_text'"
  }

  tabs_enable() {
    if [[ "$tabs_enabled" == false ]]; then
      tab_curr=1
      tab_bufs=($kak_bufname)
      tabs_enabled=true
      echo 'set global tabs_enabled true'
      echo 'hook global -group tabs WinDisplay .* %{ tab change-buf %val{bufname} }'
      echo 'hook global -group tabs BufClose .* %{ tab buf-deleted %val{hook_param} }'
    fi
    update_tab_state
  }

  tabs_disable() {
    tabs_enabled=false
    echo "set global tabs_enabled false"
    echo "rmhooks global tabs"
    update_tab_state
  }

  tab_mode() {
    if [[ "$kak_count" -ge 1 ]]; then
      tab_switch "$kak_count"
    else
      echo 'enter-user-mode tabs'
    fi
  }

  IFS=' ' read -a tab_bufs <<< "$kak_opt_tab_bufs" # XXX: Needs better parsing post-bbtu
  tab_curr="$kak_opt_tab_curr"
  tabs_enabled="$kak_opt_tabs_enabled"


  shopt -s extglob

  cmd="$1"; shift

  if [[ "$tabs_enabled" != true && "$cmd" != enable ]]; then
    echo 'prompt "Tabs are not enabled! Enable? (y/N) " '\
      '%{ eval %sh{ [ "$kak_text" = y ] && echo "tab enable" } }'
    exit
  fi

  case "$cmd" in
    change-buf  ) tab_change_buffer "$@" ;;
    buf-deleted ) tab_buf_deleted "$@" ;;

    (+([0-9])   ) tab_switch "$cmd" ;;
    d|del|delete) tab_delete "$@" ;;
    off|disable ) tabs_disable "$@" ;;
    on|enable   ) tabs_enable "$@" ;;
    list        ) tab_list "$@" ;;
    m|move      ) tab_move "$@" ;;
    mode        ) tab_mode "$@" ;;
    move-left   ) tab_move_left "$@" ;;
    move-right  ) tab_move_right "$@" ;;
    new         ) tab_new "$@" ;;
    next        ) tab_next "$@" ;;
    prev        ) tab_prev "$@" ;;
    *           ) echo "fail 'Unknown tab command'" ;;
  esac
EOF
}}

# vim-style tabnew that takes a file argument
def tabnew \
  -params ..1 -file-completion \
  -docstring 'tabnew [file]: open a new tab, optionally editing a new file' \
  %{
  tab new %sh{ [ -n "$1" ] && echo "e '$(echo "$1" | sed "s/'/''/g")'" }
}

declare-user-mode tabs
map global tabs l    ': tab list<ret>'        -docstring 'list'
map global tabs n    ': tab new<ret>'         -docstring 'new'
map global tabs ,    ': tab prev <ret>'       -docstring 'prev'
map global tabs .    ': tab next <ret>'       -docstring 'next'
map global tabs <lt> ': tab move-left<ret>'   -docstring 'move left'
map global tabs >    ': tab move-right<ret>'  -docstring 'move right'
map global tabs d    ': tab delete<ret>'      -docstring 'delete'
map global tabs m    ': tab m '               -docstring 'move'
map global tabs g    ': tab '                 -docstring 'goto'
map global tabs N    ': tab new '             -docstring 'new with cmd'

nop "Configuration" %{
  hook global WinCreate .* 'tab enable'
  map global normal <a-1> ': tab 1<ret>'
  map global normal <a-2> ': tab 2<ret>'
  map global normal <a-3> ': tab 3<ret>'
  map global normal <a-4> ': tab 4<ret>'
  map global normal <a-5> ': tab 5<ret>'
  map global normal <a-6> ': tab 6<ret>'
  map global normal <a-7> ': tab 7<ret>'
  map global normal <a-8> ': tab 8<ret>'
  map global normal <a-9> ': tab 9<ret>'
  map global normal <c-pagedown> ': tab next<ret>'
  map global normal <c-pageup> ': tab prev<ret>'
  map global user t ': tab mode<ret>' -docstring 'tabs...'
  set global modelinefmt "%%opt{tab_mode_text} %opt{modelinefmt}"
}
