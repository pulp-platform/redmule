// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
//

#include "archi_redmule.h"
#include "hal_redmule.h"
#include "redmule_utils.h"
#include <stdint.h>

#include "golden.h"
#include "w_input.h"
#include "x_input.h"
#include "y_input.h"
#include "g_input.h"
#include "s_input.h"
#include "b_input.h"
#include "z_output.h"
#define ERR 0x0011

int main() {

  uint16_t m_size = M_SIZE;
  uint16_t n_size = N_SIZE;
  uint16_t k_size = K_SIZE;

  uint8_t *x = x_inp;
  uint8_t *w = w_inp;
  uint8_t *y = y_inp;
  uint8_t *g = g_inp;
  uint8_t *s = s_inp;
  uint8_t *b = b_inp;
  uint8_t *z = z_oup; // golden_out //1c010000

  volatile int errors = 0;

#ifdef COMPLEX_OFFLOADER

  uint32_t x_addr = *(uint32_t *)&x;
  uint32_t w_addr = *(uint32_t *)&w;
  uint32_t y_addr = *(uint32_t *)&y;
  uint32_t cfg_reg0 = ((k_size << 16) | (m_size << 0));
  uint32_t cfg_reg1 = (n_size << 0);
  asm volatile("addi t0, %0, 0" ::"r"(x_addr));
  asm volatile("addi t1, %0, 0" ::"r"(w_addr));
  asm volatile("addi t2, %0, 0" ::"r"(y_addr));
  asm volatile("addi t3, %0, 0" ::"r"(cfg_reg0));
  asm volatile("addi t4, %0, 0" ::"r"(cfg_reg1));

  /* mcnfig instruction */
  // asm volatile(
  //      ".word (0x0       << 25) | \     /* Empty */
  //             (0b11101   << 20) | \     /* Rs2 */
  //             (0b11100   << 15) | \     /* Rs1 */
  //             (0x00      <<  7) | \     /* Empty */
  //             (0b0001011 <<  0)   \n"); /* OpCode */

  asm volatile(".word (0x0       << 25) | \
              (0b11101   << 20) | \
              (0b11100   << 15) | \
              (0x00      <<  7) | \
              (0b0001011 <<  0)   \n");
  /* marith instruction */
  // sm volatile(
  //     ".word (0b00111   << 27) | \     /* Rs3 */
  //            (0b00      << 25) | \     /* Empty*/
  //            (0b00110   << 20) | \     /* Rs2 */
  //            (0b00101   << 15) | \     /* Rs1 */
  //            (0b0       << 14) | \     /* Custom format enable/disable */
  //            (0b0       << 13) | \     /* Widening enable/disable */
  //            (0b001     << 10) | \     /* Operation selection */
  //            (0b001     <<  7) | \     /* Data format */
  //            (0b0101011 <<  0)   \n"); /* OpCode */

  asm volatile(".word (0b00111   << 27) | \
              (0b00      << 25) | \
              (0b00110   << 20) | \
              (0b00101   << 15) | \
              (0b0       << 14) | \
              (0b0       << 13) | \
              (0b001     << 10) | \
              (0b001     <<  7) | \
              (0b0101011 <<  0)   \n");

  asm volatile("wfi" ::: "memory");

  errors = redmule16_compare_int(y, golden, m_size * k_size / 2);

#else // COMPLEX_OFFLOADER not defined

  uint8_t float_fmt = (SRC_FMT == FP8)       ? (uint8_t)Float8
                      : (SRC_FMT == FP8ALT)  ? (uint8_t)Float8Alt
                      : (SRC_FMT == FP16)    ? (uint8_t)Float16
                      : (SRC_FMT == FP16ALT) ? (uint8_t)Float16Alt
                                             : (uint8_t)Float16;

  int gold_sum = 0, check_sum = 0;
  int i, j;

  int offload_id_tmp, offload_id;

  // Enable RedMulE
  hwpe_cg_enable();

  hwpe_soft_clear();

  while ((offload_id_tmp = hwpe_acquire_job()) < 0)
    ;
  int pace_ops = 1;
  // int pace_ops = 0;


  redmule_cfg((unsigned int)x, (unsigned int)w, (unsigned int)y, (unsigned int)g, (unsigned int)s, (unsigned int)b, m_size, n_size, k_size,
              (uint8_t)gemm_ops, float_fmt);

  // Start RedMulE operation and sleeping until the end of computation
  printf("Triggering accelerator and going to sleep...\n");
  hwpe_trigger_job();

  asm volatile("wfi" ::: "memory");

  // At the end of accelerator's computation, we resume and check on results
  printf("Resumed!\n");

  // Disable RedMulE
  hwpe_cg_disable();

  if (float_fmt == Float16 || float_fmt == Float16Alt)
    if (gemm_ops == PACE)
      errors = redmule16_compare_int(y, golden, K_SIZE * 4, 0);
    else
      errors = redmule16_compare_int(y, golden, m_size * k_size / 2, ERR);
  else if (float_fmt == Float8 || float_fmt == Float8Alt)
    errors = redmule8_compare_int(y, golden, m_size * k_size / 4, ERR);

#endif // #ifded COMPLEX_OFFLOADER

  *(int *)0x80000000 = errors;

  tfp_printf("Terminated test with %d errors. See you!\n", errors);

  return errors;
}
