# Parse the output of ipconfig and detect if it looks like I'm connected to campus ethernet.
# If so, print a string (the name of the interface connected to the campus network) and exit with
# code 0. Otherwise, print nothing and exit with code 1.

$0 ~ /^[^ ]+.*:$/ {
    interface = substr($0, 1, length($0)-1)
    disconnected = 0
    ncbi = 0
}

interface == "Ethernet adapter Ethernet" {
    split($0, fields, ":")
    if ($1 == "Media" && $2 == "State" && fields[2] == " Media disconnected") {
        disconnected = 1
    } else if ($1" "$2" "$3 == "Connection-specific DNS Suffix" && fields[2] == " ncbi.nlm.nih.gov") {
        ncbi = 1
    }
    if (ncbi && ! disconnected) {
        print interface
        exit 0
    }
}

END {
    # It will still execute END when `exit` is called earlier in the script.
    if (ncbi && ! disconnected) {
        exit 0
    }
    exit 1
}