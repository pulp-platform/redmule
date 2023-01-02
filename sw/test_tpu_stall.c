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
 *
 * Authors:  Yvan Tortorella <yvan.tortorella@unibo.it>
 *
 * This is a test that programs the DMAC in such a way that it performs 
 * transfers between L1 and L2 during the entire tensorcore computation,
 * allowing to simulate the occurrence of real case memory stalls
 */

#include "pmsis.h"
#include "pmsis/cluster/dma/cl_dma.h"
#include <stdint.h>
#include <stdio.h>

#include "hal_tpu.h"

#include "interference.h"
#include "lfsr32.h"

static int glob_errors;

uint8_t                                       l2_dummy_buffer0[1024];
uint8_t __attribute__((section(".heapsram"))) l1_dummy_buffer0[1024];
uint8_t                                       l2_dummy_buffer1[1024];
uint8_t __attribute__((section(".heapsram"))) l1_dummy_buffer1[1024];

#define DMA_BIDIRECTIONAL
#define NB_ITER 10

int run_tpu_test() {

  int err = 0;
  uint16_t in_fmp_rows  = IN_FMP_ROWS;
  uint16_t in_fmp_cols  = IN_FMP_COLS;
  uint16_t weight_cols  = WEIGHT_COLS;
  uint16_t in_feat_dim  = IN_FMP_ROWS*IN_FMP_COLS;
  uint16_t weight_dim   = IN_FMP_COLS*WEIGHT_COLS;
  uint16_t out_feat_dim = IN_FMP_ROWS*WEIGHT_COLS;

  uint8_t volatile *x = (uint8_t volatile *) pi_cl_l1_malloc(NULL, (2*in_feat_dim));
  uint8_t volatile *w = (uint8_t volatile *) pi_cl_l1_malloc(NULL, (2*weight_dim));
  uint8_t volatile *y = (uint8_t volatile *) pi_cl_l1_malloc(NULL, (2*out_feat_dim));

  // Here we write input and weight matrixes to memory
  generate_test_data_16 ((int) x, (int) w, (int) in_feat_dim, (int) weight_dim);

  // enable clock
  TPU_CG_ENABLE();

  // setup HCI
  // TPU_SETPRIORITY_TPU(); // priority to TPU w.r.t. cores, DMA
  TPU_SETPRIORITY_CORE();
  TPU_RESET_MAXSTALL();  // reset maximum stall
  TPU_SET_MAXSTALL(2);   // set maximum consecutive stall to 8 cycles for cores, DMA side

  // soft-clear TPU
  TPU_WRITE_CMD(TPU_SOFT_CLEAR, TPU_SOFT_CLEAR_ALL);
  for(volatile int kk=0; kk<10; kk++);

  // program TPU -> JOB 1
  TPU_WRITE_REG(TPU_REG_INFEAT_PTR,  x);
  TPU_WRITE_REG(TPU_REG_WEIGHTS_PTR, w);
  TPU_WRITE_REG(TPU_REG_OUTFEAT_PTR, y);

  // acquire job
  // int job_id = -1;
  // TPU_BARRIER_ACQUIRE(job_id);

  tpu_cfg (in_fmp_rows, in_fmp_cols, weight_cols);
  
  // commit TPU computation
  TPU_WRITE_CMD(TPU_TRIGGER, TPU_TRIGGER_CMD);

  // program TPU -> JOB 2
  TPU_WRITE_REG(TPU_REG_INFEAT_PTR,  x);
  TPU_WRITE_REG(TPU_REG_WEIGHTS_PTR, w);
  TPU_WRITE_REG(TPU_REG_OUTFEAT_PTR, y);

  // acquire job
  // int job_id = -1;
  // TPU_BARRIER_ACQUIRE(job_id);

  tpu_cfg (in_fmp_rows, in_fmp_cols, weight_cols);
  
  // commit TPU computation
  TPU_WRITE_CMD(TPU_TRIGGER, TPU_TRIGGER_CMD);

  TPU_BARRIER();

  // disable clock
  TPU_CG_DISABLE();

  err = compare_golden_16( (int) y, (int) out_feat_dim );
  if (err == 0)
    printf("Operation completed succesfully!\n");
  else
    printf("Ops, something went wrong... \n");

  printf("Tensorcore completed the operation with %d errors! See you space cowboy! \n", err);

  return err;
}

void run_dma_interference() {
  int tmp = 0;
  pi_cl_dma_copy_t req0, req1;
  req0.merge = 0;
  req0.size = (uint16_t) 1024;
  req0.id = 0;
  req0.ext = (uint32_t) l2_dummy_buffer0;
  req0.loc = (uint32_t) l1_dummy_buffer0;
  req1.merge = 0;
  req1.size = (uint16_t) 1024;
  req1.id = 0;
  req1.ext = (uint32_t) l2_dummy_buffer1;
  req1.loc = (uint32_t) l1_dummy_buffer1;
  req0.dir = PI_CL_DMA_DIR_EXT2LOC;
  req1.dir = PI_CL_DMA_DIR_LOC2EXT;
  // printf("DMA transfer...\n");
  do {
    // printf("Doing things...\n");
    pi_cl_dma_memcpy(&req0);
#ifdef DMA_BIDIRECTIONAL
    pi_cl_dma_memcpy(&req1);
#endif
    pi_cl_dma_wait(&req0);
#ifdef DMA_BIDIRECTIONAL
    pi_cl_dma_wait(&req1);
#endif
    req0.dir = PI_CL_DMA_DIR_LOC2EXT;
    req1.dir = PI_CL_DMA_DIR_EXT2LOC;
    pi_cl_dma_memcpy(&req0);
#ifdef DMA_BIDIRECTIONAL
    pi_cl_dma_memcpy(&req1);
#endif
    pi_cl_dma_wait(&req0);
#ifdef DMA_BIDIRECTIONAL
    pi_cl_dma_wait(&req1);
#endif
    req0.dir = PI_CL_DMA_DIR_EXT2LOC;
    req1.dir = PI_CL_DMA_DIR_LOC2EXT;
  // printf("Still doing things...\n");
  } while(!interference_flag);
  vtmp[pi_core_id()] = tmp;

  // printf("Here we are done\n");
}

// void run_cpu_interference() {
//   if(pi_core_id() == 0) {
//     int tmp = 0;
//     do {
//       for(int i=0; i<2*IN_FMP_ROWS*IN_FMP_COLS; i+=2) {
//           tmp += ne16_infeat[i];
//       }
//     } while(!interference_flag);
//     vtmp[pi_core_id()] = tmp;
//   }
//   else if(pi_core_id() == 1) {
//     int tmp = 0;
//     do {
//       for(int i=0; i<STIM_NQ_SIZE; i++) {
//           tmp += ne16_scale[i];
//       }
//     } while(!interference_flag);
//     vtmp[pi_core_id()] = tmp;
//   }
//   else if(pi_core_id() == 2) {
//     int tmp = 0;
//     do {
//       for(int i=0; i<STIM_NQS_SIZE; i++) {
//           tmp += ne16_scale_shift[i];
//       }
//     } while(!interference_flag);
//     vtmp[pi_core_id()] = tmp;
//   }
//   else if(pi_core_id() == 3) {
//     int tmp = 0;
//     do {
//       for(int i=0; i<STIM_NQB_SIZE; i++) {
//           tmp += ne16_scale_bias[i];
//       }
//     } while(!interference_flag);
//     vtmp[pi_core_id()] = tmp;
//   }
//   else if(pi_core_id() == 4) {
//     int tmp = 0;
//     do {
//       for(int i=0; i<STIM_Y_SIZE; i++) {
//           tmp += ne16_streamin[i];
//       }
//     } while(!interference_flag);
//     vtmp[pi_core_id()] = tmp;
//   }
//   else {
//     int tmp = 0;
//     do {
//       for(int i=0; i<STIM_W_SIZE; i++) {
//           tmp += ne16_weights[i];
//       }
//     } while(!interference_flag);
//     vtmp[pi_core_id()] = tmp;
//   }
// }

static struct pi_cluster_task task[1];
static struct pi_task events[1];

static void pe_entry(void *arg) {
  if(pi_core_id() == 0) {
    printf ("Core %d entered the game \n", pi_core_id());
    generate_random_buffer((int) l2_dummy_buffer0, (int) l2_dummy_buffer0 + 1024, DEFAULT_SEED);
  #ifdef DMA_BIDIRECTIONAL
    generate_random_buffer((int) l1_dummy_buffer1, (int) l1_dummy_buffer1 + 1024, DEFAULT_SEED);
  #endif
  }
  pi_cl_team_barrier();
  if(pi_core_id() == 0) {
    glob_errors = run_tpu_test();
    interference_flag = 1;
  }
  else if(pi_core_id() == 1) {
    run_dma_interference();
  }
  pi_cl_team_barrier();
}

static void cluster_entry(void *arg) {
  pi_cl_team_fork(0, pe_entry, 0);
}

static int launch_cluster_task() {
  struct pi_device cluster_dev;
  struct pi_cluster_conf conf;
  struct pi_cluster_task task;

  pi_cluster_conf_init(&conf);
  conf.id = 0;
  glob_errors = 0;

  pi_open_from_conf(&cluster_dev, &conf);
  pi_cluster_open(&cluster_dev);
  pi_freq_set(PI_FREQ_DOMAIN_FC, 5000000);
  pi_time_wait_us(1000);
  pi_freq_set(PI_FREQ_DOMAIN_FC, 50000000);
  pi_freq_set(PI_FREQ_DOMAIN_CL, 5000000);
  pi_time_wait_us(1000);
  pi_freq_set(PI_FREQ_DOMAIN_CL, 50000000);

  pi_cluster_task(&task, cluster_entry, NULL);
  pi_cluster_send_task_to_cl(&cluster_dev, &task);
  pi_cluster_close(&cluster_dev);

  return glob_errors;
}

int test_entry() {
  printf("Starting test\n");
  int errors = launch_cluster_task();
  if (errors)
    printf("Test failure\n");
  else
    printf("Test success\n");
  return errors;
}

void test_kickoff(void *arg) {
  int ret = test_entry();
  pmsis_exit(ret);
}

int main() {
  return pmsis_kickoff((void *)test_kickoff);
}
