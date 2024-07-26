# Basic syntax highlighting for strace.
# To detect strace files, add these lines to ~/.magic:
#   0 search/10 execve( strace file
#   !:mime text/x-strace

addhl shared/strace regions
addhl shared/strace/main default-region group
addhl shared/strace/string region '"' '(?<!\\)(\\\\)*"' fill string
addhl shared/strace/comment region '/\*' '\*/' fill comment
addhl shared/strace/main/ regex '^((?:\d)+?) (\w+)' 1:bullet 2:identifier
addhl shared/strace/main/ regex '\b[A-Z]{2,}\b' 0:keyword
addhl shared/strace/main/ regex '[^\n]\b(0x[0-9a-fA-F]+|-?\d+)\b' 1:value
addhl shared/strace/main/ regex '\s(=)\s(0x[0-9a-fA-F]+|-?\d+|\?)' 1:operator 2:operator
hook -group strace-highlight global WinSetOption filetype=strace %{ addhl window/strace ref strace }
hook -group strace-highlight global WinSetOption filetype=(?!strace).* %{ try %{ rmhl window/strace } }
