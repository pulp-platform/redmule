# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Arpan Suravi Prasad<prasadar@iis.ee.ethz.ch>
#

import numpy as np
import os

def float16_to_hex(f16_val):
    arr = np.array(f16_val, dtype=np.float16).reshape(())
    return f"0x{arr.view(np.uint16).item():04X}"

def silu(x):
    return x / (1 + np.exp(-x))

def exp(x):
    return np.exp(x)

# === BST Partitioning ===

def build_bst_indices(n_partitions):
    indices = list(range(1, n_partitions + 2))  # 1 to N+1 (inclusive)
    max_stage = int(np.log2(n_partitions))
    layout = [indices[0] - 1, indices[-1] - 1]  # min, max

    for stage in range(max_stage + 1):
        segment_size = 1 << (max_stage - stage + 1)
        half = segment_size // 2
        i = 0
        while i + segment_size <= len(indices):
            segment = indices[i:i + segment_size]
            center = segment[half]
            layout.append(center - 1)
            i += segment_size
    return layout

def compute_partition_index(x, breakpoints_bst, num_stages):
    path_bits = []
    trace = []
    bp_array = breakpoints_bst[2:]
    index = 0
    for stage in range(num_stages):
        if index >= len(bp_array):
            raise ValueError("Index out of bounds in BST traversal")
        bp = bp_array[index]
        bit = 1 if x > bp else 0
        path_bits.append(bit)
        trace.append(
            f"  Stage {stage}: x = {x:.6f} vs bp[{index+2}] = {bp:.6f} ({float16_to_hex(bp)}) → {'go_right' if bit else 'go_left'}"
        )
        index = 2 * index + 1 + bit
    partition_index = int("".join(map(str, path_bits)), 2)
    return partition_index, path_bits, trace

# Polynomial Approximation
def piecewise_poly_approx_bst_fp16(
    func, xmin, xmax, degree=2, partitions=8, n_stimuli=1000
):
    raw_bps = np.linspace(xmin, xmax, partitions + 1, dtype=np.float16)
    bst_indices = build_bst_indices(partitions)
    breakpoints_bst = [raw_bps[i] for i in bst_indices]

    coeffs = []
    for i in range(partitions):
        x = np.linspace(raw_bps[i], raw_bps[i + 1], 500).astype(np.float16)
        y = func(x.astype(np.float32)).astype(np.float16)
        p = np.polynomial.Polynomial.fit(x.astype(np.float32), y.astype(np.float32), deg=degree,
                                         domain=[float(raw_bps[i]), float(raw_bps[i + 1])])
        coeffs_fp16 = p.convert().coef.astype(np.float16)
        coeffs.append(coeffs_fp16)

    x_vals = np.linspace(xmin, xmax, n_stimuli + 2)[1:-1].astype(np.float16)
    y_true = func(x_vals.astype(np.float32)).astype(np.float16)
    y_approx = np.zeros_like(x_vals)

    debug_lines = []
    custom_debug_lines = []

    # breakpoint layout
    debug_lines.append("=== Raw Breakpoints (sorted) ===")
    for i, bp in enumerate(raw_bps):
        debug_lines.append(f"  raw_bp[{i}] = {bp:.6f} ({float16_to_hex(bp)})")

    debug_lines.append("\n=== BST Layout of Breakpoints ===")
    for i, idx in enumerate(bst_indices):
        debug_lines.append(f"  bst_bp[{i}] = raw_bp[{idx}] = {raw_bps[idx]:.6f} ({float16_to_hex(raw_bps[idx])})")
    debug_lines.append("")

    for idx, x in enumerate(x_vals):
        is_bypass = (x < breakpoints_bst[0]) or (x >= breakpoints_bst[1])
        if is_bypass:
            y_approx[idx] = np.float16(0.0)
            debug_lines.append(f"[{idx}] x = {x:.6f} ({float16_to_hex(x)}), bypassed\n")
            continue

        partition, path_bits, trace = compute_partition_index(x, breakpoints_bst, int(np.log2(partitions)))
        c = coeffs[partition].astype(np.float32)
        y_part = np.full(1, c[-1], dtype=np.float32)
        fma_trace = []
        for j in range(len(c) - 2, -1, -1):
            psum = y_part
            fma = (y_part * x + c[j]).astype(np.float16)
            y_part = fma.astype(np.float32)
            fma_trace.append(
                f"    FMA step {len(c)-1-j}: y = {float(psum):.5f}({float16_to_hex(psum)}) * "
                f" {float(x):.5f}({float16_to_hex(x)}) + "
                f"{float(c[j]):.5f} ({float16_to_hex(c[j])}) = {float(fma):.5f} ({float16_to_hex(fma)})"
            )

        y_approx[idx] = y_part.astype(np.float16)

        dbg = [f"[{idx}] x = {x:.6f} ({float16_to_hex(x)})"]
        dbg += trace
        dbg += [f"  Partition: {partition}, Coeffs: " + ", ".join(f"{float(ci):.5f} ({float16_to_hex(ci)})" for ci in c)]
        dbg += fma_trace
        dbg.append(f"  y_true    = {y_true[idx]:.5f} ({float16_to_hex(y_true[idx])})")
        dbg.append(f"  y_approx  = {y_approx[idx]:.5f} ({float16_to_hex(y_approx[idx])})")
        dbg.append(f"  error     = {float(y_true[idx] - y_approx[idx]):.5f}")
        debug_lines.append("\n".join(dbg) + "\n")
        if idx % 16 == 0:
            custom_debug_lines.append("\n".join(dbg))

    return {
        "x_vals": x_vals,
        "y_true": y_true,
        "y_approx": y_approx,
        "breakpoints_bst": breakpoints_bst,
        "coeffs": coeffs,
        "debug_lines": debug_lines,
        "custom_debug_lines": custom_debug_lines
    }


def write_debug_output(results, debug_file="execution.txt"):
    with open(debug_file, "w") as f:
        for line in results:
            f.write(line + "\n")
    print(f"✅ Debug written to: {debug_file}")


def write_coefficients_output(results, coeff_file="coefficients.txt"):
    with open(coeff_file, "w") as f:
        for i, coeffs in enumerate(results["coeffs"]):
            f.write(f"# Partition {i}\n")
            for j, c in enumerate(coeffs):
                f.write(f"  c[{j}] = {float(c):.8f} ({float16_to_hex(c)})\n")
            f.write("\n")
    print(f"✅ Coefficients written to: {coeff_file}")


def write_x_file(coeffs, xmin=-6, xmax=6, partitions=8, stimuli_file="x_input.h"):
    bst_indices = build_bst_indices(partitions)
    raw_bps = np.linspace(xmin, xmax, partitions + 1, dtype=np.float16)
    num_stages = int(np.log2(partitions))

    bp_coeff_array = [[0 for _ in range(8)] for _ in range(partitions)]

    for col in range(8):
        if col < num_stages:
            num_entries = 2 ** col
            index = 2 + int(2**col - 1)
            num_repeat = partitions // num_entries
            for rpt in range(num_repeat):
                for ent in range(num_entries):
                    row_idx = rpt * num_entries + ent
                    bp_coeff_array[row_idx][col] = raw_bps[bst_indices[index + ent]]
        else:
            for row in range(partitions):
                idx = (partitions - num_stages) - col - num_stages
                bp_coeff_array[row][col] = coeffs[row][idx]

    with open(stimuli_file, "w") as f_x:
        x_dim = 8 * partitions
        f_x.write(f'uint16_t x_inp[{x_dim}] = {{\n')
        for i in range(partitions):
            f_x.write('    ')
            for j in range(8):
                val = float16_to_hex(bp_coeff_array[i][j])
                end_char = ', ' if not (i == partitions - 1 and j == 7) else ' '
                f_x.write(f"{val}{end_char}")
            f_x.write('\n')
        f_x.write('};\n')
    print(f"✅ x_input header written to: {stimuli_file}")



def write_inp_inc_file(results, stimuli_file="w_input.h"):
    size = len(results["x_vals"])
    with open(stimuli_file, "w") as f:
        f.write(f' uint16_t w_inp [{size}] =' +'{')
        for i, x in enumerate(results["x_vals"]):
            if i%8==0:
                f.write('\n')
            if i == size  - 1:
                f.write(f"  {float16_to_hex(x)}\n")
            else:
                f.write(f"  {float16_to_hex(x)},")
        f.write('};\n')
    print(f"✅ Stimuli header written to: {stimuli_file}")

def write_golden_oup_inc_file(results, stimuli_file="golden.h"):
    y_approx = results["y_approx"]
    size = len(y_approx) // 2

    with open(stimuli_file, "w") as f:
        f.write(f'uint32_t golden[{size}] = {{\n')
        for i in range(0, len(y_approx), 2):
            low_16 = float16_to_hex(y_approx[i]).replace("0x", "")
            high_16 = float16_to_hex(y_approx[i + 1]).replace("0x", "")
            combined = f"0x{high_16}{low_16}"
            end_char = ',\n' if i < len(y_approx) - 2 else '\n'
            f.write(f"{combined}{end_char}")
        f.write('};\n')
    print(f"✅ Golden output header written to: {stimuli_file}")

def write_golden_inc_debug_file(results, stimuli_file="golden_debug.h"):
    y_approx = results["y_approx"]
    size = len(y_approx)

    with open(stimuli_file, "w") as f:
        f.write(f'uint32_t golden[{size}] = {{')
        for i in range(0, len(y_approx), 1):
            if i%8==0:
                f.write('\n')
            f.write(f"{float16_to_hex(y_approx[i])}, ")
        f.write('};\n')
    print(f"✅ Golden output header written to: {stimuli_file}")


def write_actual_oup_inc_file(results, stimuli_file="z_output.h"):
    size = len(results["y_approx"])
    with open(stimuli_file, "w") as f:
        f.write(f'uint16_t z_oup[{size}] = {{')
        for i in range(size):
            if i % 8 == 0:
                f.write('\n')
            val = "0xABCD"
            end_char = ',' if i < size - 1 else '\n'
            f.write(f"{val}{end_char}")
        f.write('};\n')
    print(f"✅ Dummy actual output written to: {stimuli_file}")

def write_y_inp_inc_file(stimuli_file = "y_input.h"):
    f_d = open(stimuli_file, "w")
    f_d.write('uint16_t y_inp [] = {};\n'      )
    f_d.close()

def write_tensor_dim_inc_file(stimuli_file = "tensor_dim.h", n_tests=1000):
    # Writing tensors' dimensions
    f_d = open(stimuli_file, "w")
    f_d.write('#ifndef __TENSOR_DIM__\n'       )
    f_d.write('#define __TENSOR_DIM__\n\n'     )
    f_d.write('#define M_SIZE  8 \n'           )
    f_d.write('#define N_SIZE  64\n'            )
    f_d.write(f'#define K_SIZE  {n_tests} \n')
    f_d.write('#define SRC_FMT FP16\n'         )
    f_d.write('#define DST_FMT FP16\n'         )
    f_d.write('#define FPFORMAT 16\n'          )
    f_d.write('uint8_t gemm_ops = PACE; \n'    )
    f_d.write('\n#endif\n'                     )
    f_d.close()


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser("PACE Operation Test")
    parser.add_argument( '--x_min',     type=int, default=-11 )
    parser.add_argument( '--x_max',     type=int, default=0 )
    parser.add_argument( '--f_name',    type=str, default="silu" )
    parser.add_argument( '--n_parts',   type=int, default=8 )
    parser.add_argument( '--n_deg',     type=int, default=4 )
    parser.add_argument( '--n_tests',   type=int, default=4096 )
    parser.add_argument( '--file_name', type=str, default='net_parameters.h')
    parser.add_argument( '--inc_dir',   type=str)
    parser.add_argument( '--txt_dir',   type=str)
    args = parser.parse_args()
    results = piecewise_poly_approx_bst_fp16(
        exp, xmin=args.x_min, xmax=args.x_max, degree=4, partitions=8, n_stimuli=args.n_tests
    )
    write_debug_output(debug_file=os.path.join(args.txt_dir,"execution.txt"),results=results["debug_lines"])
    write_debug_output(debug_file=os.path.join(args.txt_dir,"execution_custom.txt"),results=results["custom_debug_lines"])
    write_coefficients_output(coeff_file=os.path.join(args.txt_dir,"coefficients.txt"), results=results)
    write_inp_inc_file(results, stimuli_file=os.path.join(args.inc_dir, "w_input.h"))
    write_golden_oup_inc_file(results, stimuli_file=os.path.join(args.inc_dir, "golden.h"))
    write_actual_oup_inc_file(results, stimuli_file=os.path.join(args.inc_dir, "z_output.h"))
    write_golden_inc_debug_file(results, stimuli_file=os.path.join(args.txt_dir, "golden_debug.h"))
    write_y_inp_inc_file(stimuli_file=os.path.join(args.inc_dir, "y_input.h"))
    write_x_file(coeffs=results["coeffs"], xmin=args.x_min, xmax=args.x_max, partitions=8, stimuli_file=os.path.join(args.inc_dir, "x_input.h"))
    write_tensor_dim_inc_file(stimuli_file=os.path.join(args.inc_dir, "tensor_dim.h"), n_tests=args.n_tests)


