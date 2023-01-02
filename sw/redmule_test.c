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
 * Main Test Program for the REDMULE
 */

#include <stdint.h>
#include "stdio.h"
#include "pmsis.h"
#include "hal_redmule.h"

// #define VERBOSE
// #define VCD
#define REG_CORESTATUS 0x10000000

static int ret_value;

static void pe_entry(void *arg) {

  #ifdef VERBOSE
    printf("Entered cluster on cluster %d core %d\n", pi_cluster_id(), pi_core_id());
  #endif

  pi_cl_team_barrier();

  int errors = 0;
  int test=1; // When 0: test with lfsr | When 1: test with configurable test
  
  if (pi_core_id() == 0) 
  {
    int err = 0;
    uint16_t m_size = M_SIZE;
    uint16_t n_size = N_SIZE;
    uint16_t k_size = K_SIZE;

    uint16_t x_dim = m_size*n_size;
    uint16_t w_dim = n_size*k_size;
    uint16_t y_dim = m_size*k_size;
    uint16_t z_dim = m_size*k_size;
    uint32_t n_ops = m_size*n_size*k_size;
    uint8_t  ratio = ADDR_WIDTH/FPFORMAT;

    uint8_t volatile *x = (uint8_t volatile *) pi_cl_l1_malloc(NULL, (ratio*x_dim));
    uint8_t volatile *w = (uint8_t volatile *) pi_cl_l1_malloc(NULL, (ratio*w_dim));
    uint8_t volatile *y = (uint8_t volatile *) pi_cl_l1_malloc(NULL, (ratio*y_dim));
    uint8_t volatile *z = (uint8_t volatile *) pi_cl_l1_malloc(NULL, (ratio*z_dim));

    // Here we write input and weight matrices to memory
    generate_test_data((int) x, (int) w, (int) y, (int) x_dim, (int) w_dim, (int) y_dim, ratio);
    
    // enable clock
    REDMULE_CG_ENABLE();

    #ifdef VERBOSE
      printf ("RedMulE is now clocked! \n");
    #endif

    // setup HCI
    REDMULE_SETPRIORITY_REDMULE(); // priority to REDMULE w.r.t. cores, DMA
    REDMULE_RESET_MAXSTALL();  // reset maximum stall
    REDMULE_SET_MAXSTALL(8);   // set maximum consecutive stall to 8 cycles for cores, DMA side

    #ifdef VERBOSE
      printf ("HCI setup done \n");
    #endif

    // soft-clear REDMULE
    REDMULE_WRITE_CMD(REDMULE_SOFT_CLEAR, REDMULE_SOFT_CLEAR_ALL);
    for(volatile int kk=0; kk<10; kk++);

    #ifdef VERBOSE
      printf ("Soft clear for ReDMulE done \n");
    #endif

    // acquire job
    int job_id = -1;
    REDMULE_BARRIER_ACQUIRE(job_id);

    // set up RedMulE
    REDMULE_WRITE_REG(REDMULE_REG_X_PTR, x);
    REDMULE_WRITE_REG(REDMULE_REG_W_PTR, w);
    REDMULE_WRITE_REG(REDMULE_REG_Y_PTR, y);
    REDMULE_WRITE_REG(REDMULE_REG_Z_PTR, z);

    redmule_cfg (m_size, n_size, k_size, gemm_ops);
    // Performance counter to evaluate the performance of the accelerator
    pi_perf_conf (1 << PI_PERF_CYCLES);
    pi_perf_reset();
    pi_perf_start();

    // commit and trigger tensorcore operation
    #ifdef VCD
      *(int*)(REG_CORESTATUS) = 0xABBAABBA;
    #endif
    REDMULE_WRITE_CMD(REDMULE_TRIGGER, REDMULE_TRIGGER_CMD);

    #ifdef VERBOSE
      printf ("Commit and trigger operation done \n");
    #endif
    
    // wait for end of computation
    REDMULE_BARRIER();

    pi_perf_stop();
    uint32_t cnt_cycles_acc = pi_perf_read(PI_PERF_CYCLES);

    #ifdef VERBOSE
      printf ("RedMulE has completed the computation \n");
    #endif

    // disable clock
    REDMULE_CG_DISABLE();
    #ifdef VCD
      *(int*)(REG_CORESTATUS) = 0xDEADCACA;
    #endif
    
    #ifdef VERBOSE
      printf ("Clock disabled \n");
    #endif
      
    // set priority to core side
    REDMULE_SETPRIORITY_CORE();
    #ifdef VERBOSE
      printf("Set priprity to core. \n");
      err = compare_golden( (int) z, (int) z_dim, n_ops, ratio );
      if (err == 0)
      printf("Operation completed succesfully!\n");
      else
        printf("Ops, something went wrong... \n");
      
      printf("RedMulE completed the operation in %d cycles with %d errors! See you space cowboy! \n", cnt_cycles_acc, err);
    #else
      ret_value = compare_golden( (int) z, (int) z_dim, n_ops, ratio );
      printf("%d\n", cnt_cycles_acc);
    #endif
 
  }
  pi_cl_team_barrier();
}

static void cluster_entry(void *arg) {
  pi_cl_team_fork(0, pe_entry, 0);
}

void test_kickoff(void *arg)
{
  struct pi_device cluster_dev;
  struct pi_cluster_conf conf;
  struct pi_cluster_task task;
  ret_value = 0;

  pi_cluster_conf_init(&conf);
  conf.id = 0;

  pi_open_from_conf(&cluster_dev, &conf);
    
  pi_cluster_open(&cluster_dev);

  pi_cluster_task(&task, cluster_entry, NULL);

  pi_cluster_send_task_to_cl(&cluster_dev, &task);

  pi_cluster_close(&cluster_dev);

  pmsis_exit(ret_value);
}

int main()
{
  return pmsis_kickoff((void *)test_kickoff);
}
