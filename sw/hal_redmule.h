// Copyright 2023 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
//

#ifndef __HAL_REDMULE_H__
#define __HAL_REDMULE_H__

#include "archi_redmule.h"
#include "hwpe_ctrl_target.h"
#include <stdint.h>

/* LOW-LEVEL HAL */
#define REDMULE_ADDR_BASE REDMULE_BASE_ADD
#define REDMULE_ADDR_SPACE 0x00000100

static inline volatile redmule_regif_t *redmule_regs(void) {
  return (volatile redmule_regif_t *)REDMULE_ADDR_BASE;
}

static inline void redmule_x_add_set(unsigned int value) {
  redmule_regs()->hwpe_job_dep.marith0 = value;
}

static inline void redmule_w_add_set(unsigned int value) {
  redmule_regs()->hwpe_job_dep.marith1 = value;
}

static inline void redmule_z_add_set(unsigned int value) {
  redmule_regs()->hwpe_job_dep.marith2 = value;
}

static inline void redmule_mcfg_set(uint32_t mcfg0, uint32_t mcfg1) {
  redmule_regs()->hwpe_job_dep.mcnfig0 = mcfg0;
  redmule_regs()->hwpe_job_dep.mcnfig1 = mcfg1;
}

static inline void hwpe_trigger_job() { redmule_regs()->hwpe_ctrl.commit_trigger = 0; }

static inline int hwpe_acquire_job() {
  return (int)redmule_regs()->hwpe_ctrl.acquire;
}

static inline unsigned int hwpe_get_status() {
  return redmule_regs()->hwpe_ctrl.status;
}

static inline void hwpe_soft_clear() { redmule_regs()->hwpe_ctrl.soft_clear = 0; }

static inline void hwpe_cg_enable() { return; }

static inline void hwpe_cg_disable() { return; }

void redmule_cfg(unsigned int x, unsigned int w, unsigned int z, uint16_t m_size, uint16_t n_size,
                 uint16_t k_size, uint8_t gemm_op, uint8_t gemm_fmt) {

  uint32_t mcfg_reg0 = 0;
  uint32_t mcfg_reg1 = 0;

  mcfg_reg0 = ((uint32_t)k_size << REDMULE_REGIF__MCNFIG0__K_SIZE_bp) |
              ((uint32_t)m_size << REDMULE_REGIF__MCNFIG0__M_SIZE_bp);
  // gemm_fmt is used for both the input and the output format.
  mcfg_reg1 = ((uint32_t)n_size << REDMULE_REGIF__MCNFIG1__N_SIZE_bp) |
              ((uint32_t)gemm_op << REDMULE_REGIF__MCNFIG1__GEMM_OPS_bp) |
              ((uint32_t)gemm_fmt << REDMULE_REGIF__MCNFIG1__GEMM_INPUT_FMT_bp) |
              ((uint32_t)gemm_fmt << REDMULE_REGIF__MCNFIG1__GEMM_OUTPUT_FMT_bp);

  redmule_x_add_set(x);
  redmule_w_add_set(w);
  redmule_z_add_set(z);
  redmule_mcfg_set(mcfg_reg0, mcfg_reg1);
}

#endif
