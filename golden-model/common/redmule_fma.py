# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#

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
