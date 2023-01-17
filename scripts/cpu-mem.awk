NR > 1 {
    cpu += $3
    mem += $4
}
NR > 1 && $1 == user {
    ucpu += $3
    umem += $4
}
END {
    if (ncores) {
        printf("%-10s%0.1f%% CPU, %0.1f%% of RAM\n", user ":", ucpu/ncores, umem)
        printf("Total:    %0.1f%% CPU, %0.1f%% of RAM\n", cpu/ncores, mem)
    } else {
        printf("%-10s%0.1f%%/cpus CPU, %0.1f%% of RAM\n", user ":", ucpu, umem)
        printf("Total:    %0.1f%%/cpus CPU, %0.1f%% of RAM\n", cpu, mem)
    }
}