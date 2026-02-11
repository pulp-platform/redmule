#!/bin/bash
peakrdl regblock  redmule_regif.rdl -o regif/ --cpuif obi-flat --default-reset arst_n --hwif-report --addr-width 32
peakrdl html      redmule_regif.rdl -o regif/html/
peakrdl c-header  redmule_regif.rdl -o regif/hwpe_ctrl_target.h
# PeakRDL uses unpacked structs to avoid issues at compile time, which is commendable, but incompatible with FIFOing the output of the job! (use portable sed syntax that works on both Linux and macOS)
sed -E 's/typedef[[:space:]]+struct([[:space:]])/typedef struct packed\1/g' regif/redmule_regif_pkg.sv > regif/redmule_regif_pkg.sv.tmp && mv regif/redmule_regif_pkg.sv.tmp regif/redmule_regif_pkg.sv
