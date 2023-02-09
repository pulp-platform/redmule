/*
 * Copyright (C) 2022-2023 ETH Zurich and University of Bologna
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 * 
 * Author: Yvan Tortorella  <yvan.tortorella@unibo.it>
 *
 * High-level architecture of RedMulE
 *
 */

#ifndef __ARCHI_REDMULE_H__
#define __ARCHI_REDMULE_H__

/*
 * |=======================================================================|
 * ||                                                                     ||
 * ||Control and generic configuration register layout                    ||
 * |=======================================================================|
 * || # reg |  offset  |  bits   |   bitmask    ||  content               ||
 * ||-------+----------+---------+--------------++------------------------||
 * ||    0  |  0x0000  |  31: 0  |  0xFFFFFFFF  ||  TRIGGER               ||
 * ||    1  |  0x0008  |  31: 0  |  0xFFFFFFFF  ||  STATUS                ||
 * ||    2  |  0x0010  |  31: 0  |  0xFFFFFFFF  ||  JOBID                 ||
 * ||    3  |  0x0018  |  31: 0  |  0xFFFFFFFF  ||  SOFTCLR               ||
 * ||    4  |  0x0020  |  31: 0  |  0xFFFFFFFF  ||  PUSH                  ||
 * ||    5  |  0x0028  |  31: 0  |  0xFFFFFFFF  ||  PULL                  ||
 * |=======================================================================|
 * ||                                                                     ||
 * ||Job-dependent registers layout                                       ||
 * |=======================================================================|
 * || # reg |   bits   |   bitmask    ||  content                         ||
 * ||-------+----------+--------------++----------------------------------||
 * ||    0  |   31: 0  |  0xFFFFFFFF  ||  X_ADDR                          ||
 * ||-------+----------+--------------++----------------------------------||
 * ||    1  |   31: 0  |  0xFFFFFFFF  ||  W_ADDR                          ||
 * ||-------+----------+--------------++----------------------------------||
 * ||    2  |   31: 0  |  0xFFFFFFFF  ||  Y_ADDR                          ||
 * ||-------+----------+--------------++----------------------------------||
 * ||    3  |   31: 0  |  0xFFFFFFFF  ||  Z_ADDR                          ||
 * ||-------+----------+--------------++----------------------------------||
 * ||    4  |          |              ||  X MATRIX ITERATIONS             ||
 * ||       |   31:16  |  0xFFFF0000  ||  ROWS ITERATION                  ||
 * ||       |   15: 0  |  0x0000FFFF  ||  COLUMNS ITERATION               ||
 * ||-------+----------+--------------++----------------------------------||
 * ||    5  |          |              ||  W MATRIX ITERATIONS             ||
 * ||       |   31:16  |  0xFFFF0000  ||  ROWS ITERATION                  ||
 * ||       |   15: 0  |  0x0000FFFF  ||  COLUMNS ITERATION               ||
 * ||-------+----------+--------------++----------------------------------||
 * ||    6  |          |              ||  LEFTOVERS                       ||
 * ||       |   31:24  |  0xFF000000  ||  X/Y ROWS LEFTOVERS              ||
 * ||       |   23:16  |  0x00FF0000  ||  X COLUMNS LEFTOVERS             ||
 * ||       |   15: 8  |  0x0000FF00  ||  W ROWS LEFTOVERS                ||
 * ||       |    7: 0  |  0x000000FF  ||  W/Y COLUMNS LEFTOVERS           ||
 * ||-------+----------+--------------++----------------------------------||
 * ||    7  |          |              ||  LEFT PARAMETERS                 ||
 * ||       |   31:16  |  0xFFFF0000  ||  TOTAL NUMBER OF STORES          ||
 * ||       |   23: 0  |  0x0000FFFF  ||  -                               ||
 * ||-------+----------+--------------++----------------------------------||
 * ||    8  |   31: 0  |  0xFFFFFFFF  ||  X_D1_STRIDE                     ||
 * ||-------+----------+--------------++----------------------------------||
 * ||    9  |   31: 0  |  0xFFFFFFFF  ||  W_TOT_LENGTH                    ||
 * ||-------+----------+--------------++----------------------------------||
 * ||   10  |   31: 0  |  0xFFFFFFFF  ||  TOT_X_READ                      ||
 * ||-------+----------+--------------++----------------------------------||
 * ||   11  |   31: 0  |  0xFFFFFFFF  ||  W_D0_STRIDE                     ||
 * ||-------+----------+--------------++----------------------------------||
 * ||   12  |   31: 0  |  0xFFFFFFFF  ||  Y/Z_TOT_LENGTH                  ||
 * ||-------+----------+--------------++----------------------------------||
 * ||   13  |   31: 0  |  0xFFFFFFFF  ||  Y/Z_D0_STRIDE                   ||
 * ||-------+----------+--------------++----------------------------------||
 * ||   14  |   31: 0  |  0xFFFFFFFF  ||  Y/Z_D2_STRIDE                   ||
 * ||-------+----------+--------------++----------------------------------||
 * ||   15  |   31: 0  |  0xFFFFFFFF  ||  X_ROWS_OFFSET                   ||
 * ||-------+----------+--------------++----------------------------------||
 * ||   16  |   31: 0  |  0xFFFFFFFF  ||  X_SLOTS                         ||
 * ||-------+----------+--------------++----------------------------------||
 * ||   17  |   31: 0  |  0xFFFFFFFF  ||  X_TOT_LENGTH                    ||
 * ||-------+----------+--------------++----------------------------------||
 * ||   18  |          |              ||  OPERATION SELECTION             ||
 * ||       |   31:29  |  0xE0000000  ||  STAGE 1 ROUND MODE              ||
 * ||       |   28:26  |  0x1C000000  ||  STAGE 2 ROUND MODE              ||
 * ||       |   25:22  |  0x03C00000  ||  STAGE 1 OPERATION               ||
 * ||       |   21:18  |  0x003C0000  ||  STAGE 2 OPERATION               ||
 * ||       |   17:15  |  0x00038000  ||  INPUT FORMAT                    ||
 * ||       |   14:12  |  0x00007000  ||  COMPUTING FORMAT                ||
 * ||       |    0: 0  |  0x00000001  ||  GEMM SELECTION                  ||
 * |=======================================================================|
 *
 */

#define ARCHI_CL_EVT_ACC0 0
#define ARCHI_CL_EVT_ACC1 1
#define __builtin_bitinsert(a,b,c,d) (a | (((b << (32-c)) >> (32-c)) << d))

// RedMulE architecture
#define ADDR_WIDTH   32
#define DATA_WIDTH   256
#define REDMULE_FMT  16
#define ARRAY_HEIGHT 4
#define PIPE_REGS    3
#define ARRAY_WIDTH  12 /* Superior limit is ARRAY_HEIGHT*PIPE_REGS */

// Base address
#define REDMULE_BASE_ADD 0x00100000

// Commands
#define REDMULE_SNITCH_TRIGGER         0x00
#define REDMULE_SNITCH_STATUS          0x08
#define REDMULE_SNITCH_JOBID           0x10
#define REDMULE_SNITCH_SOFTCLR         0x18
#define REDMULE_SNITCH_PUSH            0x20
#define REDMULE_SNITCH_PULL            0x28
#define REDMULE_REG_OFFS               0

// OPs definition
#define MATMUL 0x0
#define GEMM   0x1
#define ADDMAX 0x2
#define ADDMIN 0x3
#define MULMAX 0x4
#define MULMIN 0x5
#define MAXMIN 0x6
#define MINMAX 0x7

#define RNE       0x0
#define RTZ       0x1
#define OP_FMADD  0x0
#define OP_ADD    0x2
#define OP_MUL    0x3
#define OP_MINMAX 0x7

// FP Formats encoding 
// typedef enum logic [1:0] { FP16=2'h0, FP8=2'h1, FP16ALT=2'h2, FP8ALT=2'h3 }                                                       gemm_fmt_t;
#define FP16    0x0
#define FP8     0x1
#define FP16ALT 0x2
#define FP8ALT  0x3

#endif
