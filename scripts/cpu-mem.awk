BEGIN {
    OFS = "\t"
}
NR > 1 {
    cpu += $3
    mem += $4
}
NR > 1 && $1 == user {
    ucpu += $3
    umem += $4
}
END {
    if (human) {
        if (cores) {
            printf("%-10s%0.1f%% CPU, %0.1f%% of RAM\n", user ":", ucpu/cores, umem)
            printf("Total:    %0.1f%% CPU, %0.1f%% of RAM\n", cpu/cores, mem)
        } else {
            printf("%-10s%0.1f%%/cpus CPU, %0.1f%% of RAM\n", user ":", ucpu, umem)
            printf("Total:    %0.1f%%/cpus CPU, %0.1f%% of RAM\n", cpu, mem)
        }
    } else {
        if (! cores) {
            cores = 1
        }
        if (time) {
            printf("%s\t", systime())
        }
        print cores, user, ucpu/cores, umem, cpu/cores, mem
    }
}