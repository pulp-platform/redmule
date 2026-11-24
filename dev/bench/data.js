window.BENCHMARK_DATA = {
  "lastUpdate": 1795560746318,
  "repoUrl": "https://github.com/pulp-platform/redmule",
  "entries": {
    "Execution cycles": [
      {
        "commit": {
          "author": {
            "email": "FrancescoConti@users.noreply.github.com",
            "name": "Francesco Conti",
            "username": "FrancescoConti"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "dca57a3758578d4c68af5a73cc6b76a34a5ca6a8",
          "message": "Fix leftover cases (#61)\n\n* [scheduler] fix wrong results on trailing K-dimension leftovers\n\nThe Z store geometry (z_height/z_width -> z_strb) was derived from\ny_height/y_width, which pair store-timed iterators with leftover geometry\nread from y_config_fast. y_config_fast is retired at the last Y (bias)\nload, one tile ahead of the store pipeline, so the final leftover-K store\ntile read a stale full-width geometry and wrote a full-width byte strobe,\ncorrupting adjacent memory.\n\nGive the store datapath its own store-lifetime tiling config and iterators:\n- new i_z_config_fast_fifo, popped only when the last Z store retires\n- new z_cols_iter/z_rows_iter store iterators bounded by z_config_fast\n- z_height/z_width now latch z_height_next/z_width_next computed purely\n  from store-side state, decoupled from the y_* load path\n\nVerified: 16x16x24 and 32x32x24 now pass; full active regression unchanged.\nAdds 16x16x24 / 32x32x24 K-leftover cases to the regression matrix.\n\nNote: a *small* trailing K-leftover combined with N-tiling (e.g. 30x32x18)\nremains broken via a separate z-buffer store/push race; kept commented.\n\n* [scheduler] fix bias-push overshoot on small K-leftover + N-tiling\n\nThe bias-push counter (y_push_counter) and the z-buffer bias-push index\n(d_index) terminate on the combinational y_height, which is derived from\nthe store-timed y_cols_iter_q. When a small trailing K-leftover tile's\nstore completes *mid-push* of the next tile - which happens once N-tiling\n(x_cols_iter>=2) delays the result fill - y_cols_iter advances and\ny_height flips D->w_cols_lftovr partway through a full tile's push. The\npush counter then overshoots and injects w_cols_lftovr extra bias columns\ninto the next M-block's first tile, corrupting exactly its first\nw_cols_lftovr columns (all rows). This mirrors the store-geometry bug,\nhere on the bias-push side.\n\nLatch y_push_height at push start and hold it stable for the whole push;\nuse it for y_push_counter_d, y_push_clr and cntrl_z_buffer_o.y_height.\nNo-op when y_height would not change mid-push, so passing shapes are\nunaffected.\n\nVerified: full active regression + broad even-K-leftover x N-tiling x\nM-block sweep all pass. Re-enables M30_N32_K18 and adds M16_N32_K18.\n\nNote: odd K-leftovers remain broken via a separate 32-bit misalignment\nissue (MisalignedAccessSupport=0), unaffected by this change.\n\n* [streamer] size load/store cast units to the misaligned TCDM width\n\nWith MisalignedAccessSupport=1 the HCI sink/source widen the TCDM data bus\nto DataW+32 (the extra word carries the realignment overflow). The load and\nstore cast units (redmule_castin / redmule_castout) were instantiated with\n.DataW(DataW), so they truncated the top 32 bits and dropped the realignment\nword, while be/add were forwarded full-width. Misaligned (odd-k_size) stores\ntherefore wrote 0x0000 into the realigned bytes.\n\nSize both casts to the TCDM width via\n  localparam CastDataW = DataW + (MisalignedAccessSupport ? 32 : 0);\nNo-op when MisalignedAccessSupport=0 (CastDataW == DataW), so the default\naligned configuration is unchanged.\n\nThis removes the dropped-realignment-word corruption (136 -> 68 errors on a\n16x16x17 store); a separate first-M-block corruption under misaligned mode\nremains under investigation.\n\n* [regression] misalignment support necessary for odd sizes was not working with HCI <2.6.1\n\n* [regression] Increase number of regression tests\n\n* Add performance regression page\n\n* Tune down overzealous AI-generated comments",
          "timestamp": "2026-07-13T09:49:20+02:00",
          "tree_id": "0d2085533c0b9047247fd5850353c43fba3e4701",
          "url": "https://github.com/pulp-platform/redmule/commit/dca57a3758578d4c68af5a73cc6b76a34a5ca6a8"
        },
        "date": 1783930691389,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "redmule_regression:M12_N30_K15",
            "value": 190,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K1",
            "value": 104,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K2",
            "value": 91,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K1",
            "value": 94,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K2",
            "value": 95,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K1",
            "value": 90,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K8",
            "value": 117,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K1",
            "value": 88,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K1",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K8",
            "value": 81,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K2",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K4",
            "value": 75,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K17",
            "value": 182,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K8",
            "value": 111,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K2",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K8",
            "value": 78,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N48_K48",
            "value": 1821,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M6_N32_K4",
            "value": 115,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N32_K17",
            "value": 443,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K8",
            "value": 95,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K8",
            "value": 101,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K2",
            "value": 111,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N48_K25",
            "value": 830,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K18",
            "value": 263,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K2",
            "value": 105,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32",
            "value": 849,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N30_K16",
            "value": 191,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K13",
            "value": 124,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K1",
            "value": 110,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K2",
            "value": 75,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K1",
            "value": 106,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K17",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K8",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N32_K17",
            "value": 577,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K2",
            "value": 89,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K8",
            "value": 85,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K4",
            "value": 115,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K19",
            "value": 852,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K2",
            "value": 73,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K33",
            "value": 440,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K4",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N18_K32",
            "value": 387,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M128_N128_K128",
            "value": 33081,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M30_N32_K18",
            "value": 577,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K1",
            "value": 78,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K4",
            "value": 99,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K8",
            "value": 103,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K1",
            "value": 74,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M18_N32_K16",
            "value": 255,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K2",
            "value": 107,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K4",
            "value": 107,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N20_K32",
            "value": 387,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K4",
            "value": 81,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K4",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K4",
            "value": 93,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N16_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K1",
            "value": 96,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K4",
            "value": 91,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K18",
            "value": 307,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M36_N32_K32",
            "value": 715,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K4",
            "value": 74,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N32_K2",
            "value": 241,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K4",
            "value": 77,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K8",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M30_N32_K17",
            "value": 574,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N32_K24",
            "value": 577,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K4",
            "value": 109,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K2",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K8",
            "value": 79,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K2",
            "value": 79,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K16",
            "value": 159,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K17",
            "value": 262,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K8",
            "value": 119,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K24",
            "value": 189,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K15",
            "value": 126,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M96_N96_K96",
            "value": 14025,
            "unit": "cycles"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "FrancescoConti@users.noreply.github.com",
            "name": "Francesco Conti",
            "username": "FrancescoConti"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "4c7bdf3c46483780c6f2e18f833be2ea664af36c",
          "message": "Fix N <= Height (#62)\n\n* Fix case of N<=8\n\nThis commit introduces changes to the scheduler, tiler to fix the\nnon-working case of N<=8. Specifically, this case is treated,\nfrom an internal control perspective, \"as if\" it was of a minimal\nsize equal to 16. Inputs and outputs are gated so that this does\nnot cause any additional written data.\nThe performance cost is reasonable given that anyways N<=8 cases\nshould be not considered a \"sweet spot\" of the accelerator.\n\n* Tune-down overzealous AI-generated comments\n\n* Cleanup, moving MinimumSizeN to a localparam defined from MinimumSizeNFactor = 2 multiplied by Height\n\n* Add new regression tests\n\n* Make verible happy",
          "timestamp": "2026-07-13T11:57:58+02:00",
          "tree_id": "2fa5512f7e6cb87e3f2edbf73b3ef3db609957ed",
          "url": "https://github.com/pulp-platform/redmule/commit/4c7bdf3c46483780c6f2e18f833be2ea664af36c"
        },
        "date": 1783937138086,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "redmule_regression:M16_N32_K33",
            "value": 440,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M30_N32_K18",
            "value": 577,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K8",
            "value": 78,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N3_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N3_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K1",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N30_K15",
            "value": 190,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N30_K16",
            "value": 191,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K13",
            "value": 124,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N32_K17",
            "value": 577,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N48_K48",
            "value": 1821,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K2",
            "value": 107,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M96_N96_K96",
            "value": 14025,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N32_K24",
            "value": 577,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K18",
            "value": 263,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N1_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K2",
            "value": 89,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K2",
            "value": 91,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K2",
            "value": 105,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K4",
            "value": 93,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N8_K16",
            "value": 195,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K1",
            "value": 78,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K17",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K4",
            "value": 91,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K19",
            "value": 852,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K4",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N8_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M18_N32_K16",
            "value": 255,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K24",
            "value": 189,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K2",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K2",
            "value": 79,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N2_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K1",
            "value": 88,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K8",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K1",
            "value": 90,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K4",
            "value": 74,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N4_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K1",
            "value": 106,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N8_K16",
            "value": 159,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N32_K17",
            "value": 443,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K8",
            "value": 117,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K8",
            "value": 81,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N4_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32",
            "value": 849,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N8_K24",
            "value": 189,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M33_N33_K33",
            "value": 1295,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K8",
            "value": 85,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M17_N17_K17",
            "value": 353,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K1",
            "value": 94,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K2",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K2",
            "value": 73,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K16",
            "value": 159,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N18_K32",
            "value": 387,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K8",
            "value": 103,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N2_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K4",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K18",
            "value": 307,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N48_K25",
            "value": 830,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K2",
            "value": 95,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K15",
            "value": 126,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K4",
            "value": 115,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K2",
            "value": 111,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K8",
            "value": 119,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K4",
            "value": 99,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K8",
            "value": 111,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K4",
            "value": 81,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K4",
            "value": 77,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M36_N32_K32",
            "value": 715,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N20_K32",
            "value": 387,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K17",
            "value": 262,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K1",
            "value": 110,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N16_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K1",
            "value": 104,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K4",
            "value": 75,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K2",
            "value": 75,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N1_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K1",
            "value": 96,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K4",
            "value": 109,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K2",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K8",
            "value": 95,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K8",
            "value": 79,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K4",
            "value": 107,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M6_N32_K4",
            "value": 115,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K8",
            "value": 101,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K1",
            "value": 74,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K8",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M30_N32_K17",
            "value": 574,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M128_N128_K128",
            "value": 33081,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K17",
            "value": 182,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N32_K2",
            "value": 241,
            "unit": "cycles"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "FrancescoConti@users.noreply.github.com",
            "name": "Francesco Conti",
            "username": "FrancescoConti"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "3738601e5808c27c1016cc27936d5f4b8b7e3dda",
          "message": "Enhance Verilator flow and fix REDMULE_FINISHED state issues (#63)",
          "timestamp": "2026-07-15T19:23:35+02:00",
          "tree_id": "9ad4b10a4dd6c35ec7230635466ab0df6eea550e",
          "url": "https://github.com/pulp-platform/redmule/commit/3738601e5808c27c1016cc27936d5f4b8b7e3dda"
        },
        "date": 1784136591201,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "redmule_regression:M16_N16_K24",
            "value": 189,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K2",
            "value": 91,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K1",
            "value": 104,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K2",
            "value": 95,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K33",
            "value": 440,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N30_K15",
            "value": 190,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32",
            "value": 849,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N8_K16",
            "value": 195,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M36_N32_K32",
            "value": 715,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K17",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K4",
            "value": 99,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K4",
            "value": 93,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N2_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K4",
            "value": 107,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K16",
            "value": 159,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K1",
            "value": 78,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N16_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N3_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K2",
            "value": 75,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N32_K24",
            "value": 577,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K18",
            "value": 307,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K2",
            "value": 79,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M33_N33_K33",
            "value": 1295,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K4",
            "value": 109,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K2",
            "value": 107,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K8",
            "value": 85,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K4",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K8",
            "value": 81,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N48_K25",
            "value": 830,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K4",
            "value": 75,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K4",
            "value": 74,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K8",
            "value": 103,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N8_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K4",
            "value": 91,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K1",
            "value": 74,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K1",
            "value": 88,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K1",
            "value": 106,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K8",
            "value": 101,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K2",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M6_N32_K4",
            "value": 115,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N20_K32",
            "value": 387,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K4",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K8",
            "value": 119,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N32_K17",
            "value": 443,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N32_K2",
            "value": 241,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K2",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N8_K16",
            "value": 159,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N1_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N8_K24",
            "value": 189,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K8",
            "value": 79,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K1",
            "value": 94,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K4",
            "value": 81,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N48_K48",
            "value": 1821,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M17_N17_K17",
            "value": 353,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K1",
            "value": 96,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K18",
            "value": 263,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K2",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K13",
            "value": 124,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K4",
            "value": 115,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K8",
            "value": 117,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K1",
            "value": 90,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N1_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N18_K32",
            "value": 387,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K2",
            "value": 105,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K15",
            "value": 126,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K8",
            "value": 95,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K8",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K19",
            "value": 852,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N4_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N32_K17",
            "value": 577,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K2",
            "value": 111,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K4",
            "value": 77,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N30_K16",
            "value": 191,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K8",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K17",
            "value": 182,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N2_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N3_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K8",
            "value": 78,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M96_N96_K96",
            "value": 14025,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N4_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K1",
            "value": 110,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M30_N32_K17",
            "value": 574,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K2",
            "value": 89,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K8",
            "value": 111,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K17",
            "value": 262,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M30_N32_K18",
            "value": 577,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K1",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K2",
            "value": 73,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M128_N128_K128",
            "value": 33081,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M18_N32_K16",
            "value": 255,
            "unit": "cycles"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "FrancescoConti@users.noreply.github.com",
            "name": "Francesco Conti",
            "username": "FrancescoConti"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "2af5ea4c6e8313b118dc3d307a2d89472395c9e6",
          "message": "Attempting to re-add autotriggering (to be verified) (#65)\n\n* Attempting to re-add autotriggering (to be verified)\n\n* delay autotriggering by 3 cycles\n\n* mask job triggering while jobs are running\n\n* update hwpe-ctrl\n\n* Update Bender",
          "timestamp": "2026-07-20T11:48:22+02:00",
          "tree_id": "aab7e5ee5c3b8a24506cfcdd6f9fbeb880db0c6b",
          "url": "https://github.com/pulp-platform/redmule/commit/2af5ea4c6e8313b118dc3d307a2d89472395c9e6"
        },
        "date": 1784541138627,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "redmule_regression:M128_N128_K128",
            "value": 33081,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N48_K25",
            "value": 830,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N3_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M33_N33_K33",
            "value": 1295,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K13",
            "value": 124,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K1",
            "value": 106,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K19",
            "value": 852,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K1",
            "value": 110,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K8",
            "value": 81,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K1",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N30_K16",
            "value": 191,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K1",
            "value": 74,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N8_K16",
            "value": 159,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K4",
            "value": 77,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K4",
            "value": 99,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N8_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M17_N17_K17",
            "value": 353,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K8",
            "value": 117,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K4",
            "value": 74,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N16_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N1_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N4_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K8",
            "value": 101,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N4_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K2",
            "value": 79,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K1",
            "value": 94,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N32_K2",
            "value": 241,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N2_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K2",
            "value": 105,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K4",
            "value": 107,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K4",
            "value": 93,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K2",
            "value": 73,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K8",
            "value": 103,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K1",
            "value": 96,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K4",
            "value": 115,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M30_N32_K18",
            "value": 577,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K2",
            "value": 111,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K4",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N18_K32",
            "value": 387,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K17",
            "value": 182,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K8",
            "value": 111,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N32_K17",
            "value": 443,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K4",
            "value": 81,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K4",
            "value": 91,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K1",
            "value": 88,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N32_K24",
            "value": 577,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N32_K17",
            "value": 577,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K2",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K2",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M30_N32_K17",
            "value": 574,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N2_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K1",
            "value": 90,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N3_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N48_K48",
            "value": 1821,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K4",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K2",
            "value": 95,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N20_K32",
            "value": 387,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K8",
            "value": 85,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N1_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K8",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M36_N32_K32",
            "value": 715,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K1",
            "value": 78,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K8",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K4",
            "value": 75,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N8_K16",
            "value": 195,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K18",
            "value": 307,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K8",
            "value": 79,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K17",
            "value": 262,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N30_K15",
            "value": 190,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N8_K24",
            "value": 189,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K2",
            "value": 107,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M6_N32_K4",
            "value": 115,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K1",
            "value": 104,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K18",
            "value": 263,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K2",
            "value": 75,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K2",
            "value": 91,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M18_N32_K16",
            "value": 255,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K8",
            "value": 95,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K2",
            "value": 89,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K15",
            "value": 126,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K4",
            "value": 109,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K33",
            "value": 440,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K8",
            "value": 78,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K8",
            "value": 119,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K16",
            "value": 159,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32",
            "value": 849,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K17",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M96_N96_K96",
            "value": 14025,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K24",
            "value": 189,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K2",
            "value": 113,
            "unit": "cycles"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "FrancescoConti@users.noreply.github.com",
            "name": "Francesco Conti",
            "username": "FrancescoConti"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "3423ea3d4dc57991d4244eb21e1801fa6b5d4838",
          "message": "[ci] add fixed-name gate job for required status check (#67)\n\nThe matrix job introduced in #63 reports one check per ProbStall value\n(run-hwpe-tests (ProbStall=0.0) / (ProbStall=0.25)), so the plain\n\"run-hwpe-tests\" context required by the branch ruleset was never\nreported and PRs hung on \"Waiting for status to be reported\".\n\nRename the matrix job to hwpe-tests and add an aggregate run-hwpe-tests\njob that depends on it, giving the ruleset a stable context that\nsurvives future changes to the matrix values.",
          "timestamp": "2026-07-28T15:17:37+02:00",
          "tree_id": "b8b124b1045b449cc43b2f16fffbad641083d39d",
          "url": "https://github.com/pulp-platform/redmule/commit/3423ea3d4dc57991d4244eb21e1801fa6b5d4838"
        },
        "date": 1785244991998,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "redmule_regression:M16_N16_K15",
            "value": 126,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K8",
            "value": 79,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K2",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K4",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K2",
            "value": 95,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K8",
            "value": 81,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K4",
            "value": 77,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N48_K25",
            "value": 830,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K18",
            "value": 263,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M30_N32_K17",
            "value": 574,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N32_K2",
            "value": 241,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K8",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K8",
            "value": 119,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M18_N32_K16",
            "value": 255,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N18_K32",
            "value": 387,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M33_N33_K33",
            "value": 1295,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N2_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K1",
            "value": 78,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K4",
            "value": 74,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K1",
            "value": 96,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N30_K16",
            "value": 191,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M17_N17_K17",
            "value": 353,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N32_K17",
            "value": 443,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K33",
            "value": 440,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K1",
            "value": 74,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N4_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K8",
            "value": 101,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M6_N32_K4",
            "value": 115,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M96_N96_K96",
            "value": 14025,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K1",
            "value": 110,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K13",
            "value": 124,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K19",
            "value": 852,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N32_K24",
            "value": 577,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K17",
            "value": 182,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N20_K32",
            "value": 387,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K8",
            "value": 78,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M128_N128_K128",
            "value": 33081,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K24",
            "value": 189,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K4",
            "value": 115,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M30_N32_K18",
            "value": 577,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K1",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N8_K16",
            "value": 195,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32",
            "value": 849,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N2_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K8",
            "value": 85,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K2",
            "value": 89,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N1_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K4",
            "value": 107,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K8",
            "value": 103,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K1",
            "value": 106,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K8",
            "value": 95,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K2",
            "value": 73,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K2",
            "value": 75,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N1_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N8_K16",
            "value": 159,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K17",
            "value": 262,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K8",
            "value": 117,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M36_N32_K32",
            "value": 715,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N48_K48",
            "value": 1821,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K2",
            "value": 111,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K18",
            "value": 307,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K2",
            "value": 79,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K2",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K8",
            "value": 111,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K1",
            "value": 94,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K8",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K2",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N4_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K4",
            "value": 93,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N8_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K4",
            "value": 109,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N32_K17",
            "value": 577,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K4",
            "value": 99,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K1",
            "value": 104,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K4",
            "value": 75,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N3_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K2",
            "value": 107,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K2",
            "value": 105,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K2",
            "value": 91,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K4",
            "value": 91,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K1",
            "value": 90,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K16",
            "value": 159,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N3_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K17",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N30_K15",
            "value": 190,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K4",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K1",
            "value": 88,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N8_K24",
            "value": 189,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N16_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K4",
            "value": 81,
            "unit": "cycles"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "lucabalbo2001@gmail.com",
            "name": "luca24balboni",
            "username": "luca24balboni"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "84b137b13d8d433a550a88877154ac2340c49d29",
          "message": "Added Display ifdef in redmule_top (#66)\n\nAdded an ifdef REDMULE_VERBOSE guard to suppress display statements in redmule_top.sv when debug output is not needed.",
          "timestamp": "2026-07-28T16:16:35+02:00",
          "tree_id": "a414632142c57136c9053264e9ef26ac55b210d3",
          "url": "https://github.com/pulp-platform/redmule/commit/84b137b13d8d433a550a88877154ac2340c49d29"
        },
        "date": 1785248579805,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "redmule_regression:M16_N3_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N8_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K2",
            "value": 75,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K8",
            "value": 95,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N20_K32",
            "value": 387,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N1_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N48_K48",
            "value": 1821,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K8",
            "value": 117,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N30_K16",
            "value": 191,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K16",
            "value": 159,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K2",
            "value": 73,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K2",
            "value": 79,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N48_K25",
            "value": 830,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N32_K17",
            "value": 443,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K1",
            "value": 78,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N4_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N18_K32",
            "value": 387,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K1",
            "value": 90,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K1",
            "value": 96,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K1",
            "value": 106,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K4",
            "value": 109,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K4",
            "value": 74,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K4",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K2",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K8",
            "value": 81,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K2",
            "value": 105,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K1",
            "value": 94,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K17",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K33",
            "value": 440,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K1",
            "value": 104,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N32_K2",
            "value": 241,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M17_N17_K17",
            "value": 353,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K1",
            "value": 88,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K2",
            "value": 95,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K2",
            "value": 89,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N3_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K18",
            "value": 307,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K8",
            "value": 103,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K2",
            "value": 91,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K8",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K8",
            "value": 78,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K8",
            "value": 85,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N16_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K1",
            "value": 74,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N2_K16",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K15",
            "value": 126,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N32_K17",
            "value": 577,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K1",
            "value": 110,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K4",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K8",
            "value": 101,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M128_N128_K128",
            "value": 33081,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N30_K15",
            "value": 190,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N1_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K8",
            "value": 111,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K4",
            "value": 93,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K4",
            "value": 115,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K8",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N8_K16",
            "value": 195,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N8_K16",
            "value": 159,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K24",
            "value": 189,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M30_N32_K18",
            "value": 577,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K13",
            "value": 124,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K17",
            "value": 182,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M96_N96_K96",
            "value": 14025,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M33_N33_K33",
            "value": 1295,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K4",
            "value": 99,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M30_N32_K17",
            "value": 574,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K4",
            "value": 75,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K4",
            "value": 91,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K17",
            "value": 262,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K2",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M36_N32_K32",
            "value": 715,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K4",
            "value": 107,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K2",
            "value": 111,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K4",
            "value": 81,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N2_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32",
            "value": 849,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N32_K24",
            "value": 577,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K18",
            "value": 263,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M18_N32_K16",
            "value": 255,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K4",
            "value": 77,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N8_K24",
            "value": 189,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K8",
            "value": 79,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M6_N32_K4",
            "value": 115,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K8",
            "value": 119,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K2",
            "value": 107,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N4_K1",
            "value": 71,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K1",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K19",
            "value": 852,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K2",
            "value": 72,
            "unit": "cycles"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "mbertuletti@iis.ee.ethz.ch",
            "name": "Marco Bertuletti",
            "username": "mbertuletti"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "7fa9fbe8a29e8572810ae12b92c19749045ac860",
          "message": "ROBs in Streamer for MemPool integration (#64)\n\n* Add ROB to support reordering of outstanding transactions\n\n* Bump common_cells\n\n* Update API with Register-RDL generated files\n\n* Empty z fifo in outstanding mode\n\n* Allow offset on W columns\n\n* Stop pop of next configuration when loopback is active\n\n* Add license to header file of register interface\n\n* Suppress linting on third-party generated files\n\n* Add regression tests for reordering feature\n\n* Store response ID and user for ROB operation\n\n* Disable misaligned access when enablereordering is on\n\n* Fix compilation warnings\n\n* Add regression tests for W columns offset\n\n* W columns offset on uneven dimensions",
          "timestamp": "2026-07-28T16:51:57+02:00",
          "tree_id": "440a7cf3372dee9b22bd3ff21578fff2fdecd63a",
          "url": "https://github.com/pulp-platform/redmule/commit/7fa9fbe8a29e8572810ae12b92c19749045ac860"
        },
        "date": 1785250736580,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "redmule_regression:M30_N32_K18",
            "value": 578,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K1",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K8",
            "value": 118,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K2",
            "value": 80,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K4",
            "value": 75,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N16_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K1",
            "value": 91,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K17",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N8_K24",
            "value": 190,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K2",
            "value": 73,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N4_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K2",
            "value": 96,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N30_K15",
            "value": 191,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N4_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K4",
            "value": 82,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N30_K16",
            "value": 192,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K16",
            "value": 160,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N32_K17",
            "value": 578,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K4",
            "value": 108,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K4",
            "value": 94,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K8",
            "value": 79,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N3_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K4",
            "value": 114,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K19",
            "value": 853,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K4",
            "value": 98,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N48_K25",
            "value": 831,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K8",
            "value": 86,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K4",
            "value": 92,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K33",
            "value": 441,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K8",
            "value": 104,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32_W_OFFSET7",
            "value": 1277,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M18_N32_K16",
            "value": 256,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K4",
            "value": 110,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M30_N32_K17",
            "value": 575,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N8_K16",
            "value": 160,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K18",
            "value": 264,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K1",
            "value": 111,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K8",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K24",
            "value": 190,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K8",
            "value": 98,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K4",
            "value": 76,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N8_K16",
            "value": 196,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K4",
            "value": 116,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K8",
            "value": 102,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K2",
            "value": 98,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M96_N96_K96",
            "value": 14026,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K1",
            "value": 89,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N32_K17",
            "value": 444,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K18",
            "value": 308,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N48_K48",
            "value": 1822,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M33_N33_K33",
            "value": 1296,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K8",
            "value": 80,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M17_N17_K17",
            "value": 354,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N18_K32",
            "value": 388,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K15",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32",
            "value": 850,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K1",
            "value": 75,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K2",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K17",
            "value": 263,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K1",
            "value": 95,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K4",
            "value": 100,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K1",
            "value": 73,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M36_N32_K32",
            "value": 716,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N3_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32_REORD",
            "value": 850,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N2_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K1",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K18_REORD",
            "value": 308,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32_W_OFFSET16",
            "value": 907,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K13",
            "value": 125,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N20_K32",
            "value": 388,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K8",
            "value": 96,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K2",
            "value": 90,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N8_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N1_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K2",
            "value": 108,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K17",
            "value": 183,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M6_N32_K4",
            "value": 116,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K4",
            "value": 78,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K2",
            "value": 106,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K2",
            "value": 76,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N32_K24",
            "value": 578,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K8",
            "value": 114,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N32_K2",
            "value": 242,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M128_N128_K128",
            "value": 33082,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K1",
            "value": 107,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32_W_OFFSET17",
            "value": 1292,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K8",
            "value": 82,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K1",
            "value": 105,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K2",
            "value": 114,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K1",
            "value": 79,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N2_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K8_REORD",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K2",
            "value": 92,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K8",
            "value": 120,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N1_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K2",
            "value": 74,
            "unit": "cycles"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "167587220+rfiorani@users.noreply.github.com",
            "name": "Riccardo Fiorani Gallotta",
            "username": "rfiorani"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "5a07d64df152c7f432fbd24e2971c2aa5f12b685",
          "message": "Fix x_result_valid_o condition and op_id_counter_in_q incrementing condition (#68)",
          "timestamp": "2026-09-15T23:17:16+02:00",
          "tree_id": "28ab125d9faa9c604208ea8ce0ea689fee9b30a9",
          "url": "https://github.com/pulp-platform/redmule/commit/5a07d64df152c7f432fbd24e2971c2aa5f12b685"
        },
        "date": 1789507459257,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "redmule_regression:M1_N2_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N16_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K8",
            "value": 114,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K8",
            "value": 79,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32_W_OFFSET17",
            "value": 1292,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K8",
            "value": 118,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N32_K2",
            "value": 242,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K18",
            "value": 308,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K4",
            "value": 114,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K18",
            "value": 264,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K4",
            "value": 75,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K13",
            "value": 125,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K8",
            "value": 80,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K4",
            "value": 100,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K4",
            "value": 94,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32_W_OFFSET16",
            "value": 907,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K2",
            "value": 108,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K2",
            "value": 98,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K4",
            "value": 98,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K4",
            "value": 116,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K4",
            "value": 92,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N3_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K8",
            "value": 102,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N32_K24",
            "value": 578,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K1",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K1",
            "value": 79,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K8_REORD",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K2",
            "value": 76,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N32_K17",
            "value": 578,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K33",
            "value": 441,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K2",
            "value": 96,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K17",
            "value": 183,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N8_K24",
            "value": 190,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N3_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K2",
            "value": 74,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K8",
            "value": 86,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K8",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K1",
            "value": 89,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K2",
            "value": 106,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N20_K32",
            "value": 388,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M30_N32_K18",
            "value": 578,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M128_N128_K128",
            "value": 33082,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K19",
            "value": 853,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K17",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K18_REORD",
            "value": 308,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32_W_OFFSET7",
            "value": 1277,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N32_K17",
            "value": 444,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K1",
            "value": 73,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N8_K16",
            "value": 160,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M6_N32_K4",
            "value": 116,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K2",
            "value": 73,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N30_K16",
            "value": 192,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N18_K32",
            "value": 388,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N1_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N8_K16",
            "value": 196,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N1_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K4",
            "value": 110,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K8",
            "value": 82,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K4",
            "value": 108,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K8",
            "value": 96,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M33_N33_K33",
            "value": 1296,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K4",
            "value": 76,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M18_N32_K16",
            "value": 256,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K1",
            "value": 111,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K1",
            "value": 105,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N8_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N48_K48",
            "value": 1822,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K17",
            "value": 263,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K2",
            "value": 90,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K4",
            "value": 78,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N30_K15",
            "value": 191,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32",
            "value": 850,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K15",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M30_N32_K17",
            "value": 575,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K16",
            "value": 160,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K8",
            "value": 98,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K8",
            "value": 120,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N4_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K2",
            "value": 92,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K2",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K2",
            "value": 80,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K24",
            "value": 190,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N48_K25",
            "value": 831,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K1",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K4",
            "value": 82,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M17_N17_K17",
            "value": 354,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K1",
            "value": 107,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32_REORD",
            "value": 850,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M36_N32_K32",
            "value": 716,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K1",
            "value": 75,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K1",
            "value": 95,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K1",
            "value": 91,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N2_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M96_N96_K96",
            "value": 14026,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K2",
            "value": 114,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N4_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K8",
            "value": 104,
            "unit": "cycles"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "FrancescoConti@users.noreply.github.com",
            "name": "Francesco Conti",
            "username": "FrancescoConti"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "babc299c15a508867930af5761646c5d4f932c68",
          "message": "Fix MATMUL when K is not a multiple of D (#95)\n\n* Fix MATMUL Z store width when K is not a multiple of D\n\nThe Z tile iterators and the z_height/z_width registers of the scheduler\nadvanced on flgs_z_buffer.empty, which also pulses once when the first Y\ntile of a GEMM is pushed. A MATMUL loads no Y, so its Z bookkeeping ran\none tile behind the stores: with K > D and K not a multiple of D, the\nK-leftover tile was stored D wide (overwriting the start of the next Z\nrow) and the next row block's first tile leftover-wide (leaving part of\nit unwritten).\n\n- z_buffer: new flags_o.stored, the store-completion part of empty\n  (empty is unchanged, the Y side still uses it).\n- scheduler: z_cols_iter/z_rows_iter advance on stored only; z_height and\n  z_width are the combinational size of the tile at (z_rows_iter_q,\n  z_cols_iter_q) instead of registers loaded on empty.\n\nTests:\n- regression.yml: M32_N64_K24_MATMUL (8x8, D = 16).\n- regression-16x16.yml (new): M32_N64_K48_MATMUL_16x16 (D = 32).\n- matmul.py writes y_input.h, the Z destination, filled with 0xbeef so\n  unwritten elements show up.\n- vsim.mk: RedmuleHeight/RedmuleWidth for hw-run (-gHeight/-gWidth).\n\nQuestaSim 2025.3: regression.yml 99/99 (98/99 before, only the new test\nfailing), same cycle counts on the other 98; regression-16x16.yml 1/1.\n\n* Clarify the Z completion-flag and Z iterator comments\n\n* CI: pin runners to ubuntu-24.04\n\nubuntu-latest moved to Ubuntu 26 (2026-10-19), which has no prebuilt\nVerilator 5.046 (setup-verilator: 404), no Python 3.9 for lint-license\nand no clang-format-14 package, so every job failed in setup.\n\n* Pop the Y config FIFO once per MATMUL job\n\nEvery job pushes a config into i_y_config_fifo. A MATMUL (no Y load)\npopped it on the second store-FIFO empty rise, but store_empty_rise_cnt\nwas only cleared by the Y stream done, which a MATMUL never has: after\nits pop the counter stayed at 1, the empty FIFO still showed the MATMUL\nconfig on data_o, and every later store-FIFO empty rise of the job popped\nthe empty FIFO (empty_read assertion; a $stop on Verilator). The stale\ncounter also carried into the next job, so a following MATMUL popped on\nits first rise instead of the second.\n\n- The pop is gated by ~y_config_empty.\n- The MATMUL pop clears store_empty_rise_cnt.\n- pop_i uses y_fifo_pop (the previously unused variant is replaced).\n\nVerilator 5.050 regression.yml, ProbStall 0.0 and 0.25: 99/99, no\nempty_read, same cycle counts as before on the other 98 tests.\n\n* Assign z_width/z_height directly, drop z_width_next/z_height_next\n\nThey no longer feed a register, so the _next names were misleading.\nNo functional change.",
          "timestamp": "2026-11-05T21:44:52+01:00",
          "tree_id": "6e47339922a7cf758709862a7944439fb2ac97b9",
          "url": "https://github.com/pulp-platform/redmule/commit/babc299c15a508867930af5761646c5d4f932c68"
        },
        "date": 1793911833310,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "redmule_regression:M1_N32_K1",
            "value": 105,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K1",
            "value": 107,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M17_N17_K17",
            "value": 354,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N32_K2",
            "value": 242,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N2_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K2",
            "value": 73,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K4",
            "value": 75,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N16_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K1",
            "value": 79,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32_REORD",
            "value": 850,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K4",
            "value": 94,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K8",
            "value": 98,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K2",
            "value": 96,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N30_K15",
            "value": 191,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K2",
            "value": 106,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32_W_OFFSET17",
            "value": 1292,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M96_N96_K96",
            "value": 14026,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32_W_OFFSET7",
            "value": 1277,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N48_K25",
            "value": 831,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K24",
            "value": 190,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M30_N32_K18",
            "value": 578,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N4_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K33",
            "value": 441,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K18_REORD",
            "value": 308,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K8",
            "value": 102,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K4",
            "value": 114,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K2",
            "value": 92,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K4",
            "value": 76,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N30_K16",
            "value": 192,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K8",
            "value": 80,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K8",
            "value": 86,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N8_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K18",
            "value": 308,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N32_K17",
            "value": 578,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K2",
            "value": 76,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K1",
            "value": 111,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32",
            "value": 850,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M36_N32_K32",
            "value": 716,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K1",
            "value": 89,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N48_K48",
            "value": 1822,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N8_K16",
            "value": 196,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K2",
            "value": 74,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M6_N32_K4",
            "value": 116,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K17",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N1_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N3_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N8_K16",
            "value": 160,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N18_K32",
            "value": 388,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K13",
            "value": 125,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M18_N32_K16",
            "value": 256,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K4",
            "value": 116,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K16",
            "value": 160,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K18",
            "value": 264,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K1",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K1",
            "value": 75,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N32_K17",
            "value": 444,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N4_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N20_K32",
            "value": 388,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32_W_OFFSET16",
            "value": 907,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K19",
            "value": 853,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K4",
            "value": 78,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M128_N128_K128",
            "value": 33082,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K2",
            "value": 90,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K17",
            "value": 183,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K4",
            "value": 98,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K1",
            "value": 95,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K8",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K1",
            "value": 73,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N32_K24",
            "value": 578,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K8",
            "value": 96,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K8",
            "value": 118,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K4",
            "value": 92,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K8_REORD",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K2",
            "value": 114,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K8",
            "value": 82,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K8",
            "value": 79,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K2",
            "value": 108,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N64_K24_MATMUL",
            "value": 1066,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K2",
            "value": 98,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N8_K24",
            "value": 190,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N1_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K2",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N3_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K8",
            "value": 120,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N2_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K1",
            "value": 91,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K8",
            "value": 114,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K8",
            "value": 104,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M30_N32_K17",
            "value": 575,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K4",
            "value": 110,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M33_N33_K33",
            "value": 1296,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K4",
            "value": 108,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K15",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K2",
            "value": 80,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K4",
            "value": 100,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K1",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K4",
            "value": 82,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K17",
            "value": 263,
            "unit": "cycles"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "FrancescoConti@users.noreply.github.com",
            "name": "Francesco Conti",
            "username": "FrancescoConti"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "8011693483722b4f0ac4da7066c37510eb19c86d",
          "message": "Fix the Y / Z tile width when N is not a multiple of H (#98)\n\nThe scheduler sized the Y and Z tiles as w_rows_lftovr rows (the N\nleftover) on the row block numbered w_rows_iter-1, comparing the row-block\niterators (which count the x_rows_iter row blocks of the M dimension)\nagainst the W-row count of the N dimension. With N > H, N not a multiple\nof H and at least w_rows_iter row blocks (e.g. M=128, N=9 on an 8x8\narray: w_rows_iter = 16, w_rows_lftovr = 1), row block 15 was stored\n1 row wide instead of W: the Z stream (yz_tot_len = Width * tiles) never\ncompleted, the controller stayed in COMPUTING and busy never went down.",
          "timestamp": "2026-11-16T22:55:44+01:00",
          "tree_id": "ae30ed6ac876e3ce3f744df0e64b893894680cc8",
          "url": "https://github.com/pulp-platform/redmule/commit/8011693483722b4f0ac4da7066c37510eb19c86d"
        },
        "date": 1794866587369,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "redmule_regression:M2_N24_K2",
            "value": 92,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K4",
            "value": 108,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K17",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N2_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K8_REORD",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K24",
            "value": 190,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K18",
            "value": 308,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N48_K25",
            "value": 831,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N32_K2",
            "value": 242,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N16_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K2",
            "value": 96,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K1",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M17_N17_K17",
            "value": 354,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K8",
            "value": 98,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K2",
            "value": 106,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N64_K24_MATMUL",
            "value": 1066,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K1",
            "value": 75,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K4",
            "value": 110,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N4_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K8",
            "value": 82,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K4",
            "value": 114,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N32_K17",
            "value": 444,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32_W_OFFSET7",
            "value": 1277,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K8",
            "value": 102,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N18_K32",
            "value": 388,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K1",
            "value": 79,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32_W_OFFSET16",
            "value": 907,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K2",
            "value": 90,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K8",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M128_N9_K8_MATMUL",
            "value": 554,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K8",
            "value": 114,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K1",
            "value": 111,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K2",
            "value": 76,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M6_N32_K4",
            "value": 116,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K2",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K1",
            "value": 91,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M128_N9_K8",
            "value": 674,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M36_N32_K32",
            "value": 716,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K2",
            "value": 98,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M33_N33_K33",
            "value": 1296,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K8",
            "value": 79,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M320_N9_K8_MATMUL",
            "value": 1322,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M320_N9_K8",
            "value": 1634,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N8_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K2",
            "value": 80,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N8_K16",
            "value": 160,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N16_K4",
            "value": 78,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N8_K16",
            "value": 196,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K18_REORD",
            "value": 308,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N1_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M30_N32_K17",
            "value": 575,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K16",
            "value": 160,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M30_N32_K18",
            "value": 578,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M128_N128_K128",
            "value": 33082,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N24_K4",
            "value": 94,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N1_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K2",
            "value": 73,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K8",
            "value": 96,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K8",
            "value": 80,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K17",
            "value": 183,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N32_K17",
            "value": 578,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M32_N32_K24",
            "value": 578,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K4",
            "value": 98,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K19",
            "value": 853,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M18_N32_K16",
            "value": 256,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K13",
            "value": 125,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N24_K1",
            "value": 95,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N2_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K4",
            "value": 100,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N32_K33",
            "value": 441,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N8_K24",
            "value": 190,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N20_K32",
            "value": 388,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K1",
            "value": 73,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K1",
            "value": 107,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N16_K15",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M96_N96_K96",
            "value": 14026,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K17",
            "value": 263,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N16_K4",
            "value": 75,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M24_N16_K18",
            "value": 264,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N48_K48",
            "value": 1822,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K4",
            "value": 92,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N30_K16",
            "value": 192,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K4",
            "value": 76,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M12_N30_K15",
            "value": 191,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32_W_OFFSET17",
            "value": 1292,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N24_K1",
            "value": 89,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N4_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K4",
            "value": 116,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N24_K8",
            "value": 104,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32_REORD",
            "value": 850,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N3_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K2",
            "value": 114,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N32_K2",
            "value": 108,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M16_N3_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K4",
            "value": 82,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M4_N32_K8",
            "value": 118,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K1",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M2_N16_K2",
            "value": 74,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N32_K8",
            "value": 120,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M48_N32_K32",
            "value": 850,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M8_N16_K8",
            "value": 86,
            "unit": "cycles"
          },
          {
            "name": "redmule_regression:M1_N32_K1",
            "value": 105,
            "unit": "cycles"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "FrancescoConti@users.noreply.github.com",
            "name": "Francesco Conti",
            "username": "FrancescoConti"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "be2eacf8acd48601ad8e6a85273942f5cd143484",
          "message": "[HOTFIX] Merge per-config perf results into scripts/perf.json (#99)\n\n#97 made ci-regression.sh write one perf_<cfg>.json per configuration,\nbut the benchmark step in ci.yml still reads scripts/perf.json, failing\nthe push CI on devel. Merge the per-config files into perf.json, with\ntest names prefixed by their configuration.",
          "timestamp": "2026-11-24T23:32:39+01:00",
          "tree_id": "a1bdd8ea464225fc5021ddd5ef24ba90b66a06aa",
          "url": "https://github.com/pulp-platform/redmule/commit/be2eacf8acd48601ad8e6a85273942f5cd143484"
        },
        "date": 1795560745659,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "8x8/redmule_regression:M128_N128_K128",
            "value": 33085,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M8_N16_K4",
            "value": 82,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M48_N32_K19",
            "value": 848,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M17_N17_K17",
            "value": 354,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M24_N16_K17",
            "value": 263,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M48_N32_K32",
            "value": 853,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M8_N32_K8",
            "value": 120,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M2_N16_K8",
            "value": 80,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M4_N32_K2",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M16_N8_K24",
            "value": 190,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M24_N16_K18",
            "value": 264,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M1_N24_K1",
            "value": 89,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M4_N24_K4",
            "value": 98,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M4_N16_K4",
            "value": 78,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M30_N32_K18",
            "value": 574,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M1_N16_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M320_N9_K8",
            "value": 1634,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M24_N18_K32",
            "value": 388,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M8_N16_K2",
            "value": 80,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M48_N32_K32_W_OFFSET17",
            "value": 1299,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M48_N32_K32_REORD",
            "value": 853,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M2_N24_K1",
            "value": 91,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M2_N32_K2",
            "value": 108,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M4_N32_K1",
            "value": 111,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M24_N8_K16",
            "value": 160,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M48_N48_K48",
            "value": 1825,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M8_N16_K8",
            "value": 86,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M1_N1_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M8_N16_K1",
            "value": 79,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M2_N32_K8",
            "value": 114,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M4_N24_K1",
            "value": 95,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M128_N9_K8_MATMUL",
            "value": 554,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M32_N32_K24",
            "value": 579,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M36_N32_K32",
            "value": 719,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M48_N32_K32_W_OFFSET16",
            "value": 913,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M32_N48_K25",
            "value": 840,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M1_N32_K1",
            "value": 105,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M16_N3_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M6_N32_K4",
            "value": 116,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M4_N24_K2",
            "value": 96,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M4_N24_K8",
            "value": 102,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M2_N16_K2",
            "value": 74,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M4_N16_K2",
            "value": 76,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M2_N24_K8",
            "value": 98,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M128_N9_K8",
            "value": 674,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M16_N16_K17",
            "value": 183,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M12_N30_K16",
            "value": 192,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M8_N32_K4",
            "value": 116,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M1_N24_K8",
            "value": 96,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M16_N16_K13",
            "value": 125,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M2_N24_K2",
            "value": 92,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M24_N32_K17",
            "value": 444,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M2_N32_K1",
            "value": 107,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M1_N16_K8",
            "value": 79,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M96_N96_K96",
            "value": 14029,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M1_N4_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M4_N32_K8",
            "value": 118,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M1_N32_K2",
            "value": 106,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M16_N16_K15",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M2_N24_K4",
            "value": 94,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M24_N20_K32",
            "value": 388,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M1_N32_K4",
            "value": 108,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M16_N1_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M12_N30_K15",
            "value": 191,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M8_N32_K1",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M16_N32_K33",
            "value": 444,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M1_N24_K2",
            "value": 90,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M16_N32_K18",
            "value": 311,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M16_N4_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M1_N24_K4",
            "value": 92,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M8_N24_K8",
            "value": 104,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M4_N16_K1",
            "value": 75,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M24_N32_K2",
            "value": 242,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M320_N9_K8_MATMUL",
            "value": 1322,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M8_N24_K2",
            "value": 98,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M1_N32_K8",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M8_N24_K4",
            "value": 100,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M1_N16_K4",
            "value": 75,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M2_N16_K1",
            "value": 73,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M18_N32_K16",
            "value": 256,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M32_N8_K16",
            "value": 196,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M30_N32_K17",
            "value": 573,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M32_N64_K24_MATMUL",
            "value": 1066,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M8_N16_K17",
            "value": 113,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M4_N16_K8",
            "value": 82,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M2_N32_K4",
            "value": 110,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M12_N16_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M16_N16_K24",
            "value": 190,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M8_N32_K2",
            "value": 114,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M48_N32_K32_W_OFFSET7",
            "value": 1280,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M16_N8_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M1_N2_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M24_N16_K16",
            "value": 160,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M33_N33_K33",
            "value": 1296,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M32_N32_K17",
            "value": 578,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M2_N16_K4",
            "value": 76,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M16_N32_K18_REORD",
            "value": 311,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M8_N24_K1",
            "value": 97,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M1_N32_K8_REORD",
            "value": 112,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M16_N2_K16",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M4_N32_K4",
            "value": 114,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M1_N16_K2",
            "value": 73,
            "unit": "cycles"
          },
          {
            "name": "8x8/redmule_regression:M1_N3_K1",
            "value": 72,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M32_N32_K17",
            "value": 368,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M24_N16_K17",
            "value": 236,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M16_N16_K13",
            "value": 147,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M4_N24_K4",
            "value": 146,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M8_N16_K1",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M8_N16_K17",
            "value": 204,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M16_N2_K16",
            "value": 150,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M8_N16_K4",
            "value": 130,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M2_N32_K1",
            "value": 155,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M12_N16_K16",
            "value": 146,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M128_N128_K128",
            "value": 15951,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M320_N9_K8_MATMUL",
            "value": 880,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M1_N4_K1",
            "value": 120,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M30_N32_K17",
            "value": 359,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M16_N16_K17",
            "value": 220,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M1_N1_K1",
            "value": 120,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M32_N32_K24",
            "value": 375,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M16_N32_K18_REORD",
            "value": 301,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M48_N32_K32_W_OFFSET16",
            "value": 667,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M16_N4_K16",
            "value": 150,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M2_N32_K4",
            "value": 158,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M24_N8_K16",
            "value": 158,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M2_N24_K4",
            "value": 142,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M6_N32_K4",
            "value": 166,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M1_N32_K8_REORD",
            "value": 160,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M24_N18_K32",
            "value": 332,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M1_N3_K1",
            "value": 120,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M1_N24_K2",
            "value": 138,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M1_N24_K8",
            "value": 144,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M4_N24_K1",
            "value": 143,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M1_N16_K1",
            "value": 120,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M33_N33_K33",
            "value": 994,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M32_N64_K24_MATMUL",
            "value": 544,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M1_N24_K1",
            "value": 137,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M24_N20_K32",
            "value": 332,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M2_N32_K8",
            "value": 162,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M12_N30_K15",
            "value": 185,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M17_N17_K17",
            "value": 279,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M16_N16_K15",
            "value": 149,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M16_N8_K24",
            "value": 227,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M16_N16_K24",
            "value": 227,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M1_N32_K8",
            "value": 160,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M1_N32_K1",
            "value": 153,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M30_N32_K18",
            "value": 360,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M2_N16_K8",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M48_N32_K32_W_OFFSET17",
            "value": 953,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M2_N16_K1",
            "value": 121,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M2_N16_K2",
            "value": 122,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M8_N32_K1",
            "value": 167,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M16_N32_K33",
            "value": 432,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M16_N3_K16",
            "value": 150,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M4_N32_K1",
            "value": 159,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M48_N32_K32",
            "value": 637,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M128_N9_K8",
            "value": 471,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M8_N32_K4",
            "value": 170,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M1_N16_K2",
            "value": 121,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M24_N16_K18",
            "value": 237,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M32_N8_K16",
            "value": 166,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M2_N32_K2",
            "value": 156,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M4_N32_K8",
            "value": 166,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M36_N32_K32",
            "value": 577,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M4_N16_K8",
            "value": 130,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M8_N24_K2",
            "value": 152,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M2_N24_K2",
            "value": 140,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M1_N32_K2",
            "value": 154,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M4_N16_K2",
            "value": 124,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M8_N16_K8",
            "value": 134,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M24_N32_K17",
            "value": 338,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M8_N24_K8",
            "value": 158,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M48_N32_K19",
            "value": 624,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M12_N30_K16",
            "value": 186,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M96_N96_K96",
            "value": 7013,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M4_N32_K2",
            "value": 160,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M320_N9_K8",
            "value": 1143,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M8_N32_K8",
            "value": 174,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M16_N32_K18",
            "value": 301,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M2_N24_K8",
            "value": 146,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M128_N9_K8_MATMUL",
            "value": 364,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M48_N32_K32_W_OFFSET7",
            "value": 953,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M4_N16_K4",
            "value": 126,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M1_N2_K1",
            "value": 120,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M16_N1_K16",
            "value": 150,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M4_N16_K1",
            "value": 123,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M1_N32_K4",
            "value": 156,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M8_N24_K4",
            "value": 154,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M4_N24_K2",
            "value": 144,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M8_N16_K2",
            "value": 128,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M8_N32_K2",
            "value": 168,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M24_N32_K2",
            "value": 197,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M1_N16_K4",
            "value": 123,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M4_N24_K8",
            "value": 150,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M18_N32_K16",
            "value": 198,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M1_N16_K8",
            "value": 127,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M8_N24_K1",
            "value": 151,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M16_N8_K16",
            "value": 150,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M1_N24_K4",
            "value": 140,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M48_N48_K48",
            "value": 1205,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M48_N32_K32_REORD",
            "value": 637,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M24_N16_K16",
            "value": 158,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M32_N48_K25",
            "value": 486,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M4_N32_K4",
            "value": 162,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M2_N16_K4",
            "value": 124,
            "unit": "cycles"
          },
          {
            "name": "8x32/redmule_regression:M2_N24_K1",
            "value": 139,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M2_N16_K8",
            "value": 160,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M128_N128_K128",
            "value": 9080,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M2_N16_K4",
            "value": 156,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M320_N9_K8_MATMUL",
            "value": 1131,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M2_N24_K8",
            "value": 192,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M4_N16_K1",
            "value": 155,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M33_N33_K33",
            "value": 810,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M16_N1_K16",
            "value": 182,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M2_N24_K1",
            "value": 185,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M48_N32_K32_W_OFFSET7",
            "value": 783,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M4_N32_K8",
            "value": 226,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M24_N16_K16",
            "value": 190,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M4_N16_K8",
            "value": 162,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M12_N30_K16",
            "value": 242,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M1_N16_K8",
            "value": 159,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M48_N32_K32",
            "value": 408,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M1_N3_K1",
            "value": 152,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M4_N24_K1",
            "value": 187,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M2_N24_K4",
            "value": 188,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M1_N1_K1",
            "value": 152,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M1_N16_K4",
            "value": 155,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M32_N32_K24",
            "value": 270,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M96_N96_K96",
            "value": 3929,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M18_N32_K16",
            "value": 248,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M1_N4_K1",
            "value": 152,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M16_N2_K16",
            "value": 182,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M24_N18_K32",
            "value": 238,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M1_N32_K4",
            "value": 219,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M320_N9_K8",
            "value": 1345,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M6_N32_K4",
            "value": 224,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M2_N16_K2",
            "value": 154,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M16_N16_K13",
            "value": 179,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M128_N9_K8",
            "value": 559,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M36_N32_K32",
            "value": 408,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M2_N24_K2",
            "value": 186,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M16_N32_K18",
            "value": 248,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M16_N16_K15",
            "value": 181,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M24_N32_K17",
            "value": 255,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M16_N16_K17",
            "value": 183,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M1_N24_K1",
            "value": 184,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M12_N30_K15",
            "value": 241,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M1_N32_K1",
            "value": 216,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M8_N16_K4",
            "value": 162,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M1_N24_K8",
            "value": 191,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M1_N2_K1",
            "value": 152,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M1_N32_K8",
            "value": 223,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M2_N32_K4",
            "value": 220,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M48_N32_K32_REORD",
            "value": 408,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M16_N16_K24",
            "value": 190,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M8_N32_K2",
            "value": 224,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M8_N24_K1",
            "value": 191,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M4_N16_K4",
            "value": 158,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M8_N16_K17",
            "value": 175,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M4_N32_K1",
            "value": 219,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M24_N32_K2",
            "value": 240,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M16_N8_K16",
            "value": 182,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M16_N32_K18_REORD",
            "value": 248,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M17_N17_K17",
            "value": 216,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M48_N32_K32_W_OFFSET16",
            "value": 783,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M4_N24_K2",
            "value": 188,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M12_N16_K16",
            "value": 178,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M2_N32_K2",
            "value": 218,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M8_N24_K2",
            "value": 192,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M1_N24_K2",
            "value": 185,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M4_N24_K8",
            "value": 194,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M8_N32_K8",
            "value": 230,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M16_N32_K33",
            "value": 367,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M2_N16_K1",
            "value": 153,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M16_N3_K16",
            "value": 182,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M128_N9_K8_MATMUL",
            "value": 465,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M24_N8_K16",
            "value": 190,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M48_N48_K48",
            "value": 945,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M32_N32_K17",
            "value": 263,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M8_N16_K8",
            "value": 166,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M8_N32_K4",
            "value": 226,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M1_N32_K8_REORD",
            "value": 223,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M32_N48_K25",
            "value": 345,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M4_N16_K2",
            "value": 156,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M32_N64_K24_MATMUL",
            "value": 375,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M8_N16_K1",
            "value": 159,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M32_N8_K16",
            "value": 198,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M8_N24_K4",
            "value": 194,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M16_N8_K24",
            "value": 190,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M48_N32_K19",
            "value": 395,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M48_N32_K32_W_OFFSET17",
            "value": 783,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M16_N4_K16",
            "value": 182,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M1_N16_K1",
            "value": 152,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M1_N16_K2",
            "value": 153,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M1_N32_K2",
            "value": 217,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M4_N32_K2",
            "value": 220,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M4_N24_K4",
            "value": 190,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M2_N32_K8",
            "value": 224,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M2_N32_K1",
            "value": 217,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M24_N20_K32",
            "value": 238,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M8_N16_K2",
            "value": 160,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M24_N16_K17",
            "value": 191,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M8_N32_K1",
            "value": 223,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M8_N24_K8",
            "value": 198,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M24_N16_K18",
            "value": 192,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M4_N32_K4",
            "value": 222,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M1_N24_K4",
            "value": 187,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M30_N32_K17",
            "value": 261,
            "unit": "cycles"
          },
          {
            "name": "8x32_p3/redmule_regression:M30_N32_K18",
            "value": 262,
            "unit": "cycles"
          }
        ]
      }
    ]
  }
}