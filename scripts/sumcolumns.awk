BEGIN {
  FS = "\t"
  OFS = "\t"
}
{
  for (i = 1; i <= NF; i++) {
    totals[i] += $i
  }
}
END {
  for (i = 1; totals[i] != ""; i++) {
    printf("%d\t", totals[i])
  }
  print ""
}