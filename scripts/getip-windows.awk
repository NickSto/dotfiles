BEGIN {
  OFS="\t"
}

$0 ~ /^[^ ]+.*:$/ {
    interface = substr($0, 1, length($0)-1)
}

$1 == "IPv4" && $2 == "Address." {
    split($0, fields, ":")
    gsub(/ /, "", fields[2])
    print interface, "", fields[2], ""
}