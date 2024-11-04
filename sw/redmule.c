// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
//

#include <stdint.h>
#include "redmule_utils.h"
#include "archi_redmule.h"
#include "hal_redmule.h"

#include "x_input.h"
#include "w_input.h"
#include "y_input.h"
#include "z_output.h"
#include "golden.h"

int main() {

  uint16_t m_size = M_SIZE;
  uint16_t n_size = N_SIZE;
  uint16_t k_size = K_SIZE;

  uint8_t *x = x_inp;
  uint8_t *w = w_inp;
  uint8_t *y = y_inp;
  uint8_t *z = z_oup; // golden_out //1c010000
  uint32_t *gold = golden;

  uint8_t float_fmt = (SRC_FMT == FP8)       ? (uint8_t)Float8
                      : (SRC_FMT == FP8ALT)  ? (uint8_t)Float8Alt
                      : (SRC_FMT == FP16)    ? (uint8_t)Float16
                      : (SRC_FMT == FP16ALT) ? (uint8_t)Float16Alt
                                             : (uint8_t)Float16;

  int golden_size = (float_fmt == (Float8 | Float8Alt)) ? m_size*k_size/4 : m_size*k_size/2;

  volatile int errors = 0;
  int gold_sum = 0, check_sum = 0;
  int i, j;

  int offload_id_tmp, offload_id;

  // Enable RedMulE
  hwpe_cg_enable();

  hwpe_soft_clear();

  while ((offload_id_tmp = hwpe_acquire_job()) < 0)
    ;

  redmule_cfg((unsigned int)x, (unsigned int)w, (unsigned int)y, m_size, n_size, k_size,
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
    errors = redmule16_compare_int(y, golden, m_size * k_size / 2);
  else if (float_fmt == Float8 || float_fmt == Float8Alt)
    errors = redmule8_compare_int(y, gold, m_size, k_size);

  *(int *)0x80000000 = errors;

  tfp_printf("Terminated test with %d errors. See you!\n", errors);

  return errors;
}
