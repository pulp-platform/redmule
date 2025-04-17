# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#

import sys

def generate_null_words(file_path):
    num_words = 192 * 1024
    hex_word = "00000000"
    with open(file_path, "w") as f:
        for _ in range(num_words):
            f.write(hex_word + "\n")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python generate_null_words.py <file_path>")
        sys.exit(1)

    file_path = sys.argv[1]
    generate_null_words(file_path)
    print(f"File scritto con successo in: {file_path}")
