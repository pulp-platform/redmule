// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
//

#ifndef __ARCHI_REDMULE_H__
#define __ARCHI_REDMULE_H__

#define ARCHI_CL_EVT_ACC0 0
#define ARCHI_CL_EVT_ACC1 1

// Base address
#ifndef REDMULE_BASE_ADD
#define REDMULE_BASE_ADD 0x00100000
#endif

// OPs definition
#define MATMUL 0x0
#define GEMM 0x1
#define ADDMAX 0x2
#define ADDMIN 0x3
#define MULMAX 0x4
#define MULMIN 0x5
#define MAXMIN 0x6
#define MINMAX 0x7
#define PACE 0x8

// GEMM formats
#define Float8 0x0
#define Float16 0x1
#define Float8Alt 0x2
#define Float16Alt 0x3

// FP Formats encoding
#define FP16 0x2
#define FP8 0x3
#define FP16ALT 0x4
#define FP8ALT 0x5

#endif
