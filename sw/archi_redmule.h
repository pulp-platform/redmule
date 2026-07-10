// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
//

#ifndef __ARCHI_REDMULE_H__
#define __ARCHI_REDMULE_H__

/*
 * Register map aligned to the SystemRDL interface (rtl/ctrl/redmule_regif.rdl).
 * The job-dependent block now lives at offset 0x20 (was 0x40), configuration
 * registers come first, and the operation/format selection is folded into
 * mcnfig1 (there is no separate arithmetic register any more).
 *
 * |========================================================================|
 * ||                                                                      ||
 * ||Control and generic configuration register layout                     ||
 * |========================================================================|
 * || # reg |  offset  |  bits   |   bitmask    ||  content                ||
 * ||-------+----------+---------+--------------++-------------------------||
 * ||    0  |  0x0000  |   1: 0  |  0x00000003  ||  COMMIT_TRIGGER         ||
 * ||    1  |  0x0004  |  31: 0  |  0xFFFFFFFF  ||  ACQUIRE                ||
 * ||    2  |  0x0008  |  31: 0  |  0xFFFFFFFF  ||  reserved0              ||
 * ||    3  |  0x000c  |  31: 0  |  0xFFFFFFFF  ||  STATUS                 ||
 * ||    4  |  0x0010  |   7: 0  |  0x000000FF  ||  RUNNING_JOB            ||
 * ||    5  |  0x0014  |   1: 0  |  0x00000003  ||  SOFT_CLEAR             ||
 * |========================================================================|
 * ||                                                                      ||
 * ||Job-dependent registers layout (base 0x20)                            ||
 * |========================================================================|
 * || # reg |  offset  |  bits   |   bitmask    ||  content                ||
 * ||-------+----------+---------+--------------++-------------------------||
 * ||    0  |  0x0020  |         |              ||  Matrix Config 0 (mcnfig0)||
 * ||       |          |  31:16  |  0xFFFF0000  ||  K Size (W Columns)     ||
 * ||       |          |  15: 0  |  0x0000FFFF  ||  M Size (X Rows)        ||
 * ||-------+----------+---------+--------------++-------------------------||
 * ||    1  |  0x0024  |         |              ||  Matrix Config 1 (mcnfig1)||
 * ||       |          |  26:25  |  0x06000000  ||  Output format          ||
 * ||       |          |  24:23  |  0x01800000  ||  Input format           ||
 * ||       |          |  22:20  |  0x00700000  ||  Operation selection    ||
 * ||       |          |  19:16  |  0x000F0000  ||  send/receive stream    ||
 * ||       |          |  15: 0  |  0x0000FFFF  ||  N Size (X Cols/W Rows) ||
 * ||-------+----------+---------+--------------++-------------------------||
 * ||    2  |  0x0028  |  31: 0  |  0xFFFFFFFF  ||  Matrix Config 2 (mcnfig2)||
 * ||       |          |         |              ||  Y offset (bias)        ||
 * ||-------+----------+---------+--------------++-------------------------||
 * ||    3  |  0x002C  |  31: 0  |  0xFFFFFFFF  ||  X_ADDR (marith0)       ||
 * ||-------+----------+---------+--------------++-------------------------||
 * ||    4  |  0x0030  |  31: 0  |  0xFFFFFFFF  ||  W_ADDR (marith1)       ||
 * ||-------+----------+---------+--------------++-------------------------||
 * ||    5  |  0x0034  |  31: 0  |  0xFFFFFFFF  ||  Z_ADDR (marith2)       ||
 * ||-------+----------+---------+--------------++-------------------------||
 * ||    6  |  0x0038  |  31: 0  |  0xFFFFFFFF  ||  MOPCNT (RO)            ||
 * |========================================================================|
 *
 */

#define ARCHI_CL_EVT_ACC0 0
#define ARCHI_CL_EVT_ACC1 1

// RedMulE architecture
#define ADDR_WIDTH 32
#define DATA_WIDTH 256
#define REDMULE_FMT 16
#define ARRAY_HEIGHT 4
#define PIPE_REGS 3
#define ARRAY_WIDTH 12 /* Superior limit is ARRAY_HEIGHT*PIPE_REGS */

// Base address
#define REDMULE_BASE_ADD 0x00100000

// Commands (mandatory control block @ 0x00)
#define REDMULE_TRIGGER 0x00 // commit_trigger[1:0]: writing 0 commits + starts the job
#define REDMULE_ACQUIRE 0x04
#define REDMULE_FINISHED 0x08 // reserved0 in the RDL map
#define REDMULE_STATUS 0x0C
#define REDMULE_RUNNING_JOB 0x10
#define REDMULE_SOFT_CLEAR 0x14 // soft_clear[1:0]: writing 0 clears everything (incl. regfile)

// Job-dependent registers (base 0x20; config first, then X/W/Z addresses)
#define REDMULE_REG_OFFS 0x20
#define REDMULE_MCFG0_PTR 0x00  // -> 0x20  mcnfig0: k_size[31:16], m_size[15:0]
#define REDMULE_MCFG1_PTR 0x04  // -> 0x24  mcnfig1: n[15:0], stream[19:16], ops[22:20], in_fmt[24:23], out_fmt[26:25]
#define REDMULE_MCFG2_PTR 0x08  // -> 0x28  mcnfig2: y_offs[31:0]
#define REDMULE_REG_X_PTR 0x0C  // -> 0x2C  marith0: x_addr
#define REDMULE_REG_W_PTR 0x10  // -> 0x30  marith1: w_addr
#define REDMULE_REG_Z_PTR 0x14  // -> 0x34  marith2: z_addr
#define REDMULE_MOPCNT_PTR 0x18 // -> 0x38  mopcnt (RO)

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
