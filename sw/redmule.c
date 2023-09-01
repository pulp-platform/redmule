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
 * RedMulE SW test
 */

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

  volatile int errors = 0;
  int gold_sum = 0, check_sum = 0;
  int i,j;
  
  int offload_id_tmp, offload_id;

  // Enable RedMulE
  hwpe_cg_enable();

  hwpe_soft_clear();

  while( ( offload_id_tmp = hwpe_acquire_job() ) < 0);
  
  // job-dependent registers
  redmule_x_add_set ((unsigned int) x);
  redmule_w_add_set ((unsigned int) w);
  redmule_y_add_set ((unsigned int) y);
  redmule_z_add_set ((unsigned int) z);
  // _Bool is_gemm = 1;
  redmule_cfg (m_size, n_size, k_size, gemm_ops);

  // Start RedMulE operation
  hwpe_trigger_job();

  // Wait for end of computation
  asm volatile ("wfi" ::: "memory");

  // Disable RedMulE
  hwpe_cg_disable();

  errors = redmule16_compare_int(z, golden, m_size*k_size/2);

  *(int *) 0x80000000 = errors;

  tfp_printf ("Terminated test with %d errors. See you!\n", errors);

  return errors;
}
