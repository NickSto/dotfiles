BEGIN {
  OFS="\t"
}
# Get the interface name.
$1 ~ /^[0-9]:$/ && $2 ~ /:$/ {
  # If we'\''re at the interface name line, we either just started or just finished the previous
  # interface. If so, print the previous one.
  if (iface && (ipv4 || ipv6)) {
    print iface, mac, ipv4, ipv6
  }
  split($2, fields, ":")
  iface=fields[1]
  mac = ""
  ipv4 = ""
  ipv6 = ""
}
# Get the MAC address.
$1 == "link/ether" {
  mac = $2
}
# Get the IPv4 address.
$1 == "inet" && $5 == "scope" && $6 == "global" {
  split($2, fields, "/")
  ipv4=fields[1]
}
# Get the IPv6 address.
# "temporary" IPv6 addresses are the ones which aren'\''t derived from the MAC address:
# https://en.wikipedia.org/wiki/IPv6_address#Modified_EUI-64
$1 == "inet6" && $3 == "scope" && $4 == "global" && $5 == "temporary" {
  split($2, fields, "/")
  # Avoid private addresses:
  # https://serverfault.com/questions/546606/what-are-the-ipv6-public-and-private-and-reserved-ranges/546619#546619
  if (substr(fields[1], 1, 2) != "fd") {
    ipv6=fields[1]
  }
}
# Print the last interface.
END {
  if (iface && (ipv4 || ipv6)) {
    print iface, mac, ipv4, ipv6
  }
}