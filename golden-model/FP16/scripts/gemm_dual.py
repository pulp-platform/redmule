# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Yvan Tortorella <yvan.tortorella@unibo.it>
#

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
import argparse
import dump_utils as dump
import os

# COMPUTE:
# Z[m_size, k_size] = ( X[m_size, n_size] max W[n_size, k_size] ) + Y[m_size, k_size]

#Visualize data with more precision
torch.set_printoptions(precision=10, sci_mode=False)

parser = argparse.ArgumentParser("mm Operation Test")
parser.add_argument( '--m_size', type=int, default=3 )
parser.add_argument( '--n_size', type=int, default=3 )
parser.add_argument( '--k_size', type=int, default=3 )
parser.add_argument( '--file_name', type=str, default='net_parameters.h')
parser.add_argument( '--inc_dir', type=str)
parser.add_argument( '--txt_dir', type=str)
args = parser.parse_args()

# Network parameters
m_size = args.m_size
n_size = args.n_size
k_size = args.k_size

f = open(args.file_name, "w")

# We want to perform a GEMM, of the kind Z = Y + X*W
# Test Matrices
X_MM = torch.rand(m_size, n_size)
W_MM = torch.rand(n_size, k_size)
Y_MM = torch.zeros(m_size, k_size)
X_GEMM = torch.rand(m_size, n_size)
W_GEMM = torch.rand(n_size, k_size)

import numpy as np

def bittrue_fma(a, x, b):
    # Simulate FP16 FMA with intermediate rounding
    a_fp32 = np.float16(a).astype(np.float64)
    x_fp32 = np.float16(x).astype(np.float64)
    b_fp32 = np.float16(b).astype(np.float64)
    result = a_fp32 * x_fp32 + b_fp32
    return np.float16(result).astype(np.float64)

def matrix_multiply_with_bittrue_fma(X, W, Y):
    M, K = X.shape
    K2, N = W.shape
    assert K == K2, "Inner dimensions must match"

    Z = np.zeros((M, N), dtype=np.float64)

    for m in range(M):
        for n in range(N):
            acc = Y[m, n].astype(np.float64)  # Start with Y as accumulator
            for k in range(K):
                acc = bittrue_fma(X[m, k], W[k, n], acc)
            Z[m, n] = acc
    Z = Z.astype(np.float16)

    return Z

Z_MM = matrix_multiply_with_bittrue_fma(X_MM.cpu().numpy(), W_MM.cpu().numpy(), Y_MM.cpu().numpy())
Z_MM = torch.from_numpy(Z_MM).to(dtype=torch.float16)
Z_GEMM = matrix_multiply_with_bittrue_fma(X_GEMM.cpu().numpy(), W_GEMM.cpu().numpy(), Z_MM.cpu().numpy())
Z_GEMM = torch.from_numpy(Z_GEMM).to(dtype=torch.float16)

in_rows  = str(m_size)
in_cols  = str(n_size)
out_cols = str(k_size)
x_dim    = str(m_size*n_size)
w_dim    = str(n_size*k_size)
y_dim    = str(m_size*k_size)
z_dim    = str(m_size*k_size)
out_int  = str(int(m_size*k_size/2))
header   = ""

# ------------------------------------------------------------------------------------#
#                             Header files generation                                 #
# ------------------------------------------------------------------------------------#

# Path to the genereted files
inc_path = args.inc_dir
for f in os.listdir(inc_path):
    os.remove(os.path.join(inc_path, f))

f_x = open(''+inc_path+'/xmm.h', "w")
f_x.write(''+header+'')
f_x.write('uint16_t x_mm ['+x_dim+'] = {\n')
for i in range(m_size):
    for j in range (n_size):
        x_bin = bin(np.float16(X_MM[i][j]).view('H'))[2:].zfill(16)
        x_hex = hex(int(x_bin, 2))[2:]
        if (i == m_size - 1 and j == n_size - 1):
          f_x.write('0x'+x_hex+' ')
        else:
          f_x.write('0x'+x_hex+', ')
    f_x.write("\n")
f_x.write("};")
f_x.close()

f_w = open(''+inc_path+'/wmm.h', "w")
f_w.write(''+header+'')
f_w.write('uint16_t w_mm ['+w_dim+'] = {\n')
for i in range(n_size):
    for j in range (k_size):
        w_bin = bin(np.float16(W_MM[i][j]).view('H'))[2:].zfill(16)
        w_hex = hex(int(w_bin, 2))[2:]
        if (i == n_size - 1 and j == k_size - 1):
          f_w.write('0x'+w_hex+' ')
        else:
          f_w.write('0x'+w_hex+', ')
    f_w.write("\n")
f_w.write("};")
f_w.close()

f_y = open(''+inc_path+'/ymm.h', "w")
f_y.write(''+header+'')
f_y.write('uint16_t y_mm ['+y_dim+'] = {\n')
for i in range(m_size):
    for j in range (k_size):
        y_bin = bin(np.float16(Y_MM[i][j]).view('H'))[2:].zfill(16)
        y_hex = hex(int(y_bin, 2))[2:]
        if (i == m_size - 1 and j == k_size - 1):
          f_y.write('0x'+y_hex+' ')
        else:
          f_y.write('0x'+y_hex+', ')
    f_y.write("\n")
f_y.write("};")
f_y.close()

f_z = open(''+inc_path+'/zmm.h', "w")
f_z.write(''+header+'')
f_z.write('uint16_t z_mm ['+z_dim+'] = {\n')
for i in range(m_size):
    for j in range (k_size):
        z_bin = bin(np.float16(Z_MM[i][j]).view('H'))[2:].zfill(16)
        z_hex = hex(int(z_bin, 2))[2:]
        if (i == m_size - 1 and j == k_size - 1):
          f_z.write('0x'+z_hex+' ')
        else:
          f_z.write('0x'+z_hex+', ')
    f_z.write("\n")
f_z.write("};")
f_z.close()

f_x = open(''+inc_path+'/xgemm.h', "w")
f_x.write(''+header+'')
f_x.write('uint16_t x_gemm ['+x_dim+'] = {\n')
for i in range(m_size):
    for j in range (n_size):
        x_bin = bin(np.float16(X_GEMM[i][j]).view('H'))[2:].zfill(16)
        x_hex = hex(int(x_bin, 2))[2:]
        if (i == m_size - 1 and j == n_size - 1):
          f_x.write('0x'+x_hex+' ')
        else:
          f_x.write('0x'+x_hex+', ')
    f_x.write("\n")
f_x.write("};")
f_x.close()

f_w = open(''+inc_path+'/wgemm.h', "w")
f_w.write(''+header+'')
f_w.write('uint16_t w_gemm ['+w_dim+'] = {\n')
for i in range(n_size):
    for j in range (k_size):
        w_bin = bin(np.float16(W_GEMM[i][j]).view('H'))[2:].zfill(16)
        w_hex = hex(int(w_bin, 2))[2:]
        if (i == n_size - 1 and j == k_size - 1):
          f_w.write('0x'+w_hex+' ')
        else:
          f_w.write('0x'+w_hex+', ')
    f_w.write("\n")
f_w.write("};")
f_w.close()

f_z = open(''+inc_path+'/zgemm.h', "w")
f_z.write(''+header+'')
f_z.write('uint16_t z_gemm ['+z_dim+'] = {\n')
for i in range(m_size):
    for j in range (k_size):
        z_bin = bin(np.float16(Z_GEMM[i][j]).view('H'))[2:].zfill(16)
        z_hex = hex(int(z_bin, 2))[2:]
        if (i == m_size - 1 and j == k_size - 1):
          f_z.write('0x'+z_hex+' ')
        else:
          f_z.write('0x'+z_hex+', ')
    f_z.write("\n")
f_z.write("};")
f_z.close()

# Writing tensors' dimensions
f_d = open(''+inc_path+'/tensor_dim.h', "w")
f_d.write(''+header+'')
f_d.write('#ifndef __TENSOR_DIM__\n'       )
f_d.write('#define __TENSOR_DIM__\n\n'     )
f_d.write('#define M_SIZE  '+in_rows+' \n' )
f_d.write('#define N_SIZE  '+in_cols+' \n' )
f_d.write('#define K_SIZE  '+out_cols+'\n' )
f_d.write('#define SRC_FMT FP16\n'         )
f_d.write('#define DST_FMT FP16\n'         )
f_d.write('#define FPFORMAT 16\n'          )
f_d.write('uint8_t gemm_ops = GEMM; \n'    )
f_d.write('\n#endif\n'                     )
f_d.close()
