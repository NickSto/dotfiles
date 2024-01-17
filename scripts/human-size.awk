BEGIN {
  units[0] = ""
  units[1] = "K"
  units[2] = "M"
  units[3] = "G"
  units[4] = "T"
  units[5] = "P"
  units[6] = "E"
  units[7] = "Y"
}
{
  bytes = $1
  for (i = length(units)-1; i >= 0; i--) {
    scale = 1024**i
    if (bytes >= scale || (i == 0 && bytes == 0)) {
      prefix = units[i]
      if (prefix) {
        unit = prefix "B"
      } else {
        unit = "bytes"
      }
      if (bytes/scale >= 10 || bytes == 0) {
        print int(bytes/scale) " " unit
      } else {
        printf("%0.1f %s\n", bytes/scale, unit)
      }
      break
    }
  }
}