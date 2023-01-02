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
 * Utilities
 */

#include "utils.h"

// Funcion that generates input data for RedMulE
void generate_test_data (int x_start_addr, int w_start_addr, int y_start_addr, int x_dim, int w_dim, int y_dim, uint8_t ratio) {
  int x_addr     = x_start_addr;
  int w_addr     = w_start_addr;
  int y_addr     = y_start_addr;
  int x_end_addr = x_addr + (ratio*x_dim); 
  int w_end_addr = w_addr + (ratio*w_dim); 
  int y_end_addr = y_addr + (ratio*y_dim);
  int x_data     = 0;
  int w_data     = 0;
  int y_data     = 0;
  int counter    = 0;

  // Generating X stimuli from golden model
  for (x_addr = x_start_addr; x_addr < x_end_addr; x_addr += ratio) {
    int x = x_addr - x_start_addr;
    *(uint32_t *)(x_addr) = x_inp[x/ratio];
    // printf("X written: %2x \n", *(uint32_t *)(in_addr));
  }

  // Generating W stimuli from golden model
  for (w_addr = w_start_addr; w_addr < w_end_addr; w_addr += ratio) {
    int w = w_addr - w_start_addr;
    *(uint32_t *)(w_addr) = w_inp[w/ratio];
    // printf("W written: %2x \n", *(uint32_t *)(weight_addr));
  }

  // Generating Y stimuli from golden model
  for (y_addr = y_start_addr; y_addr < y_end_addr; y_addr += ratio) {
    int y = y_addr - y_start_addr;
    *(uint32_t *)(y_addr) = y_inp[y/ratio];
    // printf("Y written: %2x \n", *(uint32_t *)(y_addr));
  }

}

/* 
* Function that compares RedMulE result with the golden data stored in inc/z_out.h,
* with a tolerance of two bits precision between hw/sw calculation 
*/
int compare_golden (int z_start_addr, int z_dim, int n_ops, uint8_t ratio) {
  int err = 0;
  int z_end_addr = z_start_addr + ratio*z_dim;
  uint16_t z_computed;
  uint16_t diff, diff_1, diff_2;
  uint16_t inaccurate = 0;

  for (int z_addr = z_start_addr; z_addr < z_end_addr; z_addr += ratio) {
    int z = z_addr - z_start_addr;
    z_computed = *(uint32_t *)(z_addr);
    //diff = out_computed - golden_out[out/2];
    // printf("Computed: %x, golden: %x, index: %d\n", z_computed, z_oup[z/ratio], z/ratio);

    // Here we evaluate if the results differ for more than two bits in the least significant hexadecimal figure
    if ( z_computed != z_oup[z/ratio] ) { 
      //printf("Computed %2x, expected %2x, index: %d \n", out_computed, golden_out[out/2], out/2);
      inaccurate++;
      diff_1 = z_computed - z_oup[z/ratio]; // Here we compute the difference between results and golden model
      if (diff_1 > 3) {  // diff > 0x0011 -> this can happen if golden_out > out_computed, so we evaluate the other case
        diff_2 = z_oup[z/ratio] - z_computed; // Here we compute the difference between golden model and results
          if (diff_2 > 3) { // diff > 0x0011 -> if this happened, something went wrong
            //printf("Computed %2x, expected %2x \n", out_computed, golden_out[out/2]);
            err++;
            //printf("Error %d, index is %d \n", err, out/2);
          }
      }
    }
  }
  //printf("%d inaccurate results over %d computations.\n", inaccurate, n_ops);

  return err;

}

// int matmul_fp16 (uint16_t in_fmp_rows, uint16_t in_fmp_cols, uint16_t weight_cols){
// // uint16_t matmul_fp16 (int in_start_addr, int weight_start_addr) {
//   const uint16_t bits       = 16;
//   const uint16_t exp_bits   = 5;
//   const uint16_t man_bits   = 10;
//   const uint16_t bias       = pow(2, exp_bits - 1) - 1;
//   const uint16_t sign_mask  = (1 << (exp_bits + man_bits)); // --> 1 00000 00 0000 0000
//   const uint16_t exp_mask   = ((1 << 5) - 1) << man_bits;   // --> 0 11111 00 0000 0000
//   const uint16_t man_mask   = (1 << man_bits) - 1;          // --> 0 00000 11 1111 1111
//   const uint16_t hidden_bit = (1 << 10);                    // --> 0 00001 00 0000 0000
//   const uint16_t zero       = 0 | (bias << man_bits) | 0;   // --> 0 11111 00 0000 0000
//   const uint32_t GRS_mask   = 111 >> 29;
//   uint16_t partial_prod, prod;
//   uint16_t f1, f2, f3;
// 
//   // printf("Read %2x and %2x \n", f1, f2);
//   for (int i = 0; i < in_fmp_rows; i++) { // in_fmp_rows
//     for (int k = 0; k < weight_cols; k++) { // weight_cols
//       partial_prod = 0;
//       for (int j = 0; j < in_fmp_cols; j++) { // in_fmp_cols
//         f1 = x_inp[i][j];
//         f2 = w_inp[j][k];
//         f3 = partial_prod;
//         // printf("cycle %d: f1 = %2x, f2 = %2x, f3 = %2x \n", j, f1, f2, f3);
// 
//         _Bool    prod_sign = (f1 & sign_mask) ^ (f2 & sign_mask);
//         int      prod_exp  = 0;
//         int      prod_man  = 0;
//         if (f1 == 0 | f2 == 0)
//           prod = 0;
//         else {
//           // uint16_t result    = 0;
// 
//           int   exp1 = (f1 & exp_mask) >> man_bits;
//           int   exp2 = (f2 & exp_mask) >> man_bits;
//           int   man1 = (f1 & man_mask) | hidden_bit;
//           int   man2 = (f2 & man_mask) | hidden_bit;
//           // printf("Computed exp1: %2x, exp2: %2x, man1: %2x, man2: %2x \n", exp1, exp2, man1, man2);
// 
//           // Add exponents
//           prod_exp = exp1 + exp2 - bias;  // Remove double bias
//           // printf("prod_exp is %2x \n", prod_exp);
// 
//           // Multiply significants
//           prod_man = man1 * man2;   // 11 bit * 11 bit ? 22 bit!
//           // printf("prod_man = %2x \n", prod_man);
//           // Shift 22bit int right to fit into 10 bit
//           if (highest_bit_set(prod_man) == 21) {
//               prod_man >>= 11;
//               prod_man += 1;
//               prod_exp += 1;
//           } else {
//               prod_man >>= 10;
//           }
//           prod_man &= ~hidden_bit;    // Remove hidden bit
//           // printf("prod_man is %2x \n", prod_man);
// 
//           // Construct float
//           prod = prod_sign | (prod_exp << man_bits) | prod_man;
//           // printf("prod %2x = %2x \n", j, prod);
//         }
// 
//         _Bool acc_sign = 0;
//         int   acc_exp  = 0;
//         int   acc_man  = 0;
//         if (f3 == 0)
//           partial_prod = prod;
//         else {
//           prod_man |= hidden_bit;
//           _Bool sum_sign = (f3 & sign_mask);
//           int   sum_exp  = (f3 & exp_mask) >> man_bits;
//           int   sum_man  = (f3 & man_mask) | hidden_bit;
//           // printf("sum_sign: %2x, sum_exp: %2x, sum_man: %2x \n", sum_sign, sum_exp, sum_man);
// 
//           if (sum_exp > prod_exp){             // --> Adder exponent is bigger than product one
//             acc_exp = sum_exp;                 // --> Keep the bigger exponent as final one
//             prod_man >>= (sum_exp - prod_exp); // --> Shift right the mantissa of the product of the amount of the exponents' distance
//           } else if (prod_exp > sum_exp) {     // --> Opposite case, product exponent grater than addend one. Repeat previous passages reversed
//             acc_exp = prod_exp;
//             sum_man >>= (prod_exp - sum_exp);
//           }
//           // printf("acc_exp: %2x, sum_man: %2x \n", acc_exp, sum_man);
// 
//           // Mantissas sum
//           acc_man = prod_man + sum_man;
//           // printf("acc_man: %2x \n", acc_man);
// 
//           if (highest_bit_set(acc_man) == 11) {
//             acc_man >>= 1;
//             acc_exp += 1;
//           }
//           acc_man += 1;
// 
//           // return acc_sign | (acc_exp << man_bits) | (acc_man & ~hidden_bit);
//           partial_prod = acc_sign | (acc_exp << man_bits) | (acc_man & ~hidden_bit);
//         }
//         // printf("mac %d_th: %2x \n", j, partial_prod);
//       }
//     }
//   }
//   return partial_prod;
// }

int highest_bit_set (int man){
  uint16_t count = 0;
  int      store = -1;

  while (man != 0){
    if ((man & 1) == 1)
      store = count;
    man = man >> 1;
    count ++;
    // printf("man: %2x, count: %2x, store: %2x \n", man, count, store);
  }

  if (store == -1) // --> no highest bit set
    return 0;
  else             // --> store contains the highest bit position
    return store;
}
