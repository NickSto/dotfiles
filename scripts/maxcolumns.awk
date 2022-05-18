BEGIN {
  FS = "\t"
  OFS = "\t"
}
substr($0,1,1) != "#" {
  for (i = 1; i <= NF; i++) {
    # `$i+0 == $i` makes sure the value is a number.
    if ($i+0 == $i && $i > maximums[i]) {
      maximums[i] = $i
    }
  }
}
END {
  for (i = 1; maximums[i] != ""; i++) {
    printf("%d\t", maximums[i])
  }
  print ""
}