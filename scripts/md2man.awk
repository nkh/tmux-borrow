#!/usr/bin/awk -f
# scripts/md2man.awk — fallback manpage renderer for the markdown subset our
# man/*.md sources use, used by `make man` when pandoc is absent.
#
# Source convention (the same files pandoc -s -t man renders):
#   YAML front matter at the very top (between leading --- fences):
#       ---
#       title: tum-borrow
#       section: 1
#       header: tmux-borrow Manual
#       ---
#     -> .TH tum-borrow 1 "" "tmux-borrow Manual"
#   H1 / H2:   ## NAME / ## SYNOPSIS       -> .SH NAME / .SH SYNOPSIS  (uppercased)
#   H3:        ### Options                 -> .SS Options
#   code fence: ```                         -> .nf / .fi  (toggles)
#   bullets:   - item                       -> .IP \(bu 2 + text
#   blank line:                            -> .PP
#   else:      plain text                   -> escaped roff line
#
# Intentionally small; for richer formatting install pandoc and `make man`
# will use it instead.

BEGIN { code = 0; yaml = 0; th_done = 0; title = ""; section = "1"; header = "" }

# leading --- opens the YAML block
/^---[ \t]*$/ && !yaml && NR == 1 { yaml = 1; next }
# a closing --- ends the YAML block (and emits .TH once)
/^---[ \t]*$/ && yaml {
  yaml = 0
  printf ".TH %s %s \"\" \"%s\" \"tmux-borrow\"\n", title, section, (header ? header : "")
  th_done = 1
  next
}

# inside YAML: capture title / section / header
yaml && /^title:/      { sub(/^title:[ \t]*/, "");      title   = $0; next }
yaml && /^section:/    { sub(/^section:[ \t]*/, "");    section = $0; next }
yaml && /^header:/     { sub(/^header:[ \t]*/, "");     header  = $0; next }
yaml { next }

# code fence toggles no-fill mode
/^```/ {
  if (!code) { print ".nf"; code = 1 } else { print ".fi"; code = 0 }
  next
}

# if no YAML block was used, the first H1 "# name(sec)" is the title
/^# / && !th_done {
  line = substr($0, 3)
  if (match(line, /\([^)]*\)/)) {
    section = substr(line, RSTART + 1, RLENGTH - 2)
    title = substr(line, 1, RSTART - 1)
    gsub(/[ \t]+$/, "", title)
  } else {
    title = line
  }
  printf ".TH %s %s \"\" \"tmux-borrow Manual\" \"tmux-borrow\"\n", title, section
  th_done = 1
  next
}

# H1 / H2 -> .SH (uppercased)
/^##? / {
  sub(/^#+[ \t]*/, "")
  print ".SH " toupper($0)
  next
}

# H3 -> .SS
/^### / {
  sub(/^###[ \t]*/, "")
  print ".SS " $0
  next
}

# blank line -> paragraph break (only outside code)
/^[ \t]*$/ {
  if (!code) print ".PP"
  next
}

# bullet
/^[-*][ \t]/ {
  sub(/^[-*][ \t]+/, "")
  print ".IP \\(bu 2"
  print roff_escape($0)
  next
}

# plain text
{
  print roff_escape($0)
}

function roff_escape(s,    r) {
  r = s
  gsub(/\\/, "\\\\", r)        # \ -> \\
  gsub(/^\./, "\\&.", r)       # leading . -> \&.
  return r
}
