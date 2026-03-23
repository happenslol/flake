rgnc() { rg -uuu -p --colors match:none -o ".{0,50}$1.{0,50}" | rg -C 9 "$1" ;}

fcopy() {
  local uris=""
  for f in "$@"; do
    uris+="file://$(realpath "$f")\n"
  done
  printf "%b" "$uris" | sed '/^$/d' | wl-copy -t text/uri-list
}
