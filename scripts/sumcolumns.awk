BEGIN {
  FS = "\t"
  OFS = "\t"
}
substr($0,1,1) != "#" {
  for (i = 1; i <= NF; i++) {
    # Non-numbers get converted to 0
    totals[i] += $i
  }
}
END {
  for (i = 1; totals[i] != ""; i++) {
    printf("%d\t", totals[i])
  }
  print ""
}