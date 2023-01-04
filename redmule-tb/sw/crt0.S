/*
 * Copyright (C) 2018-2019 ETH Zurich and University of Bologna
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
 */

/*
 * Authors: Germain Haugou, ETH (germain.haugou@iis.ee.ethz.ch)
 *          Francesco Conti, ETHZ & UNIBO
 */

  .section .text
  .global _start
_start:

  # Cluster PEs will also starts here to avoid aligning another entry point
  # Just re-route them to the right entry
  csrr    a0, 0xF14
  andi    a1, a0, 0x1f
  srli    a0, a0, 5

  # clear the bss segment
  la      t0, _bss_start
  la      t1, _bss_end
1:
  sw      zero,0(t0)
  addi    t0, t0, 4
  bltu    t0, t1, 1b

  /* Stack initialization */
  la   x2, stack

.section .text

  // On all other chips we simply pass 0.
  addi  a0, x0, 0
  addi  a1, x0, 0

  // Jump to main program entry point (argc = a0, argv = a1).
  la    t2, main
  jalr  x1, t2
  mv    s0, a0

  /* If program returns from main, call exit routine */
  mv   a0, s0
  wfi

  .global _init
  .global _fini
_init:
_fini:
  # These don't have to do anything since we use init_array/fini_array.
  ret

.section .vectors, "ax"
.option norvc;

  .org 0x80
  jal x0, _start

