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
 * Utilities' header
 */

#include "pmsis.h"
#include <stdint.h> 
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "inc/x_input.h"
#include "inc/w_input.h"
#include "inc/y_input.h"
#include "inc/z_output.h"

// Matrices stored as two-dimensional arrays
#include "inc/x_2D.h"
#include "inc/w_2D.h"

void generate_test_data (int x_start_addr, int w_start_addr, int y_start_addr, int x_dim, int w_dim, int y_dim, uint8_t ratio);

int compare_golden (int z_start_addr, int z_dim, int n_ops, uint8_t ratio);

//void matmul_fp16 (int in_start_addr, int weight_start_addr);
int matmul_fp16 (uint16_t in_fmp_rows, uint16_t in_fmp_cols, uint16_t weight_cols);
int highest_bit_set (int man);
