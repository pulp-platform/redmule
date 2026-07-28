#!/bin/bash
# Copyright 2025 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

peakrdl regblock  redmule_regif.rdl -o regif/ --cpuif passthrough --default-reset arst_n --hwif-report --addr-width 32
peakrdl html      redmule_regif.rdl -o regif/html/
peakrdl c-header  redmule_regif.rdl -o ../../sw/hwpe_ctrl_target.h
awk '
  /#include <assert.h>/ {
    print
    print ""
    print "#if defined(__cplusplus)"
    print "#define REDMULE_STATIC_ASSERT(cond, msg) static_assert(cond, msg)"
    print "#elif defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 201112L)"
    print "#define REDMULE_STATIC_ASSERT(cond, msg) _Static_assert(cond, msg)"
    print "#else"
    print "#define REDMULE_STATIC_ASSERT_CONCAT_(a, b) a##b"
    print "#define REDMULE_STATIC_ASSERT_CONCAT(a, b) REDMULE_STATIC_ASSERT_CONCAT_(a, b)"
    print "#define REDMULE_STATIC_ASSERT(cond, msg) \\"
    print "  typedef char REDMULE_STATIC_ASSERT_CONCAT(redmule_static_assert_, __LINE__)[(cond) ? 1 : -1]"
    print "#endif"
    next
  }
  {
    gsub(/static_assert\(/, "REDMULE_STATIC_ASSERT(")
    print
  }
' ../../sw/hwpe_ctrl_target.h > ../../sw/hwpe_ctrl_target.h.tmp && mv ../../sw/hwpe_ctrl_target.h.tmp ../../sw/hwpe_ctrl_target.h
# PeakRDL uses unpacked structs to avoid issues at compile time, which is commendable, but incompatible with FIFOing the output of the job! (use portable sed syntax that works on both Linux and macOS)
sed -E 's/typedef[[:space:]]+struct([[:space:]])/typedef struct packed\1/g' regif/redmule_regif_pkg.sv > regif/redmule_regif_pkg.sv.tmp && mv regif/redmule_regif_pkg.sv.tmp regif/redmule_regif_pkg.sv

# PeakRDL does not emit a license header; prepend the repository's SPDX header to the generated SystemVerilog.
HEADER='// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51'
for f in regif/redmule_regif.sv regif/redmule_regif_pkg.sv ../../sw/hwpe_ctrl_target.h; do
  printf '%s\n' "$HEADER" | cat - "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done
