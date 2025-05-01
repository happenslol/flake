rgnc() { rg -uuu -p --colors match:none -o ".{0,50}$1.{0,50}" | rg -C 9 "$1" ;}
