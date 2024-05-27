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
#include "tinyprintf.h"
#include "archi_redmule.h"
#include "hal_redmule.h"

#include "inc/x_input.h"
#include "inc/w_input.h"
#include "inc/y_input.h"
#include "inc/z_output.h"
#include "inc/golden.h"

#define IGNORE_BITS_COMPARE 0x00070007

int redmule16_compare_int(uint32_t *actual_z, uint32_t *golden_z, int len) {
  #define ERR 0x0011
  uint32_t actual_word = 0;
  uint16_t actual_MSHWord, actual_LSHWord;
  uint32_t golden_word = 0;
  uint16_t golden_MSHWord, golden_LSHWord;
  uint32_t actual = 0;
  uint32_t golden = 0;

  int errors = 0;
  int error;

  for (int i=0; i<len; i++) {
    error = 0;
    actual_word = *(actual_z+i);
    golden_word = *(golden_z+i);

    // int error = ((actual_word ^ golden_word) & ~IGNORE_BITS_COMPARE) ? 1 : 0;
    uint16_t diff = 0;
    
    // Chechink Least Significant Half-Word
    actual_LSHWord = (uint16_t)(actual_word & 0x0000FFFF);
    golden_LSHWord = (uint16_t)(golden_word & 0x0000FFFF);

    diff = (actual_LSHWord > golden_LSHWord) ? (actual_LSHWord - golden_LSHWord) : 0;
    diff = (actual_LSHWord < golden_LSHWord) ? (golden_LSHWord - actual_LSHWord) : 0;

    if (diff > ERR) {
      error = 1;
      #ifdef VERBOSE
        tfp_printf ("diff: 0x%08x\n", diff);
        tfp_printf ("LSW: Error!\n");
      #endif
    }

    // Checking Most Significant Half-Word
    actual_MSHWord = (uint16_t)((actual_word >> 16) & 0x0000FFFF);
    golden_MSHWord = (uint16_t)((golden_word >> 16) & 0x0000FFFF);

    diff = (actual_MSHWord > golden_MSHWord) ? (actual_MSHWord - golden_MSHWord) : 0;
    diff = (actual_MSHWord < golden_MSHWord) ? (golden_MSHWord - actual_MSHWord) : 0;

    if (diff > ERR) {
      error = 1;
      #ifdef VERBOSE
        tfp_printf ("diff: 0x%08x\n", diff);
        tfp_printf ("MSW: Error!\n");
      #endif
    }
    
    errors += error;

    // tfp_printf("  Golden: 0x%08x; Actual: 0x%08x,\n", golden_word, actual_word);
    #ifdef VERBOSE
      if(error) {
        if(errors==1) tfp_printf("  golden     <- actual     @ address    @ index\n");
        tfp_printf("  0x%08x <- 0x%08x @ 0x%08x @ 0x%08x\n", golden_word, actual_word, (actual_z+i), i*4);
      }
    #endif
  }
  return errors;
}

int redmule8_compare_int(uint32_t *actual_z, uint32_t *golden_z, int len) {
  #define ERR 0x0011
  uint32_t actual_word = 0;
  uint8_t  actual_Byte0,
           actual_Byte1,
           actual_Byte2,
           actual_Byte3;
  uint32_t golden_word = 0;
  uint8_t  golden_Byte0,
           golden_Byte1,
           golden_Byte2,
           golden_Byte3;
  uint32_t actual = 0;
  uint32_t golden = 0;

  int errors = 0;
  int error;

  for (int i=0; i<len; i++) {
    error = 0;
    actual_word = *(actual_z+i);
    golden_word = *(golden_z+i);

    // int error = ((actual_word ^ golden_word) & ~IGNORE_BITS_COMPARE) ? 1 : 0;
    uint8_t diff = 0;
    
    // Cheching Byte0
    actual_Byte0 = (uint8_t)(actual_word & 0x000000FF);
    golden_Byte0 = (uint8_t)(golden_word & 0x000000FF);

    diff = (actual_Byte0 > golden_Byte0) ? (actual_Byte0 - golden_Byte0) : 0;
    diff = (actual_Byte0 < golden_Byte0) ? (golden_Byte0 - actual_Byte0) : 0;

    if (diff > ERR) {
      error = 1;
      tfp_printf ("diff: 0x%08x\n", diff);
      tfp_printf ("Byte0: Error!\n");
    }

    // Cheching Byte1
    actual_Byte1 = (uint8_t)( (actual_word >> 8 ) & 0x000000FF);
    golden_Byte1 = (uint8_t)( (golden_word >> 8 ) & 0x000000FF);

    diff = (actual_Byte1 > golden_Byte1) ? (actual_Byte1 - golden_Byte1) : 0;
    diff = (actual_Byte1 < golden_Byte1) ? (golden_Byte1 - actual_Byte1) : 0;

    if (diff > ERR) {
      error = 1;
      tfp_printf ("diff: 0x%08x\n", diff);
      tfp_printf ("Byte1: Error!\n");
    }

    // Cheching Byte2
    actual_Byte2 = (uint8_t)( (actual_word >> 16 ) & 0x000000FF);
    golden_Byte2 = (uint8_t)( (golden_word >> 16 ) & 0x000000FF);

    diff = (actual_Byte2 > golden_Byte2) ? (actual_Byte2 - golden_Byte2) : 0;
    diff = (actual_Byte2 < golden_Byte2) ? (golden_Byte2 - actual_Byte2) : 0;

    if (diff > ERR) {
      error = 1;
      tfp_printf ("diff: 0x%08x\n", diff);
      tfp_printf ("Byte2: Error!\n");
    }

    // Cheching Byte3
    actual_Byte3 = (uint8_t)( (actual_word >> 24 ) & 0x000000FF);
    golden_Byte3 = (uint8_t)( (golden_word >> 24 ) & 0x000000FF);

    diff = (actual_Byte3 > golden_Byte3) ? (actual_Byte3 - golden_Byte3) : 0;
    diff = (actual_Byte3 < golden_Byte3) ? (golden_Byte3 - actual_Byte3) : 0;

    if (diff > ERR) {
      error = 1;
      tfp_printf ("diff: 0x%08x\n", diff);
      tfp_printf ("Byte3: Error!\n");
    }
    
    errors += error;

    // tfp_printf("  Golden: 0x%08x; Actual: 0x%08x,\n", golden_word, actual_word);
    #ifdef VERBOSE
      if(error) {
        if(errors==1) tfp_printf("  golden     <- actual     @ address    @ index\n");
        tfp_printf("  0x%08x <- 0x%08x @ 0x%08x @ 0x%08x\n", golden_word, actual_word, (actual_z+i), i*4);
      }
    #endif
  }
  return errors;
}

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

  volatile int data_correctable_cnt, data_uncorrectable_cnt = 0;

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

  data_correctable_cnt = redmule_get_data_correctable_count();
  data_uncorrectable_cnt = redmule_get_data_uncorrectable_count();
  tfp_printf ("errors corrected: %d \n", data_correctable_cnt);
  tfp_printf ("errors uncorrectable: %d \n", data_uncorrectable_cnt);

  errors = redmule16_compare_int(z, golden, m_size*k_size/2);
  // errors = redmule8_compare_int(z, golden, m_size*k_size/4);

  *(int *) 0x80000000 = errors;
}

void generate_test_data_16 (int in_start_addr, int weight_start_addr, int in_feat_dim, int weight_dim) {
  int in_addr         = in_start_addr;
  int weight_addr     = weight_start_addr;
  int in_end_addr     = in_start_addr + (2*in_feat_dim); 
  int weight_end_addr = weight_addr   + (2*weight_dim); 
  int in_data         = 0;
  int weight_data     = 0;
  int counter         = 0;

  // Generating input stimuli from golden model
  for (in_addr = in_start_addr; in_addr < in_end_addr; in_addr += 2) {
    int in = in_addr - in_start_addr;
    *(uint32_t *)(in_addr) = x_inp[in/2];
    //printf("Input written: %2x \n", *(uint32_t *)(in_addr));
  }

  // Generating Weight stimuli from golden model
  for (weight_addr = weight_start_addr; weight_addr < weight_end_addr; weight_addr += 2) {
    int w = weight_addr - weight_start_addr;
    *(uint32_t *)(weight_addr) = w_inp[w/2];
    //printf("Weight written: %2x \n", *(uint32_t *)(weight_addr));
  }

}
