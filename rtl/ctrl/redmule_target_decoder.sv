// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Francesco Conti <f.conti@unibo.it>
//

//
// This file contains a memory-mapped target interface for RedMulE.
//

module redmule_target_decoder
  import redmule_pkg::*;
  import redmule_regif_pkg::*;
#(
  parameter  int unsigned OpIdWidth = 4
)(
  input  logic                clk_i,
  input  logic                rst_ni,
  input  logic                clear_i,
  output logic                target_clear_o,
  input  logic                config_ready_i,
  input  logic                op_done_i,
  output logic                config_valid_o,
  output redmule_config_t     config_o,
  // target port
  hwpe_ctrl_intf_periph.slave target
);

  // target signals
  logic                                     job_trigger;
  logic                                     job_done;
  logic [31:0]                              job_status;
  redmule_regif__hwpe_ctrl_job_indep__out_t job_indep_regs;
  logic                                     job_dep_regs_valid;
  redmule_regif__hwpe_ctrl_job_dep__out_t   job_dep_regs;

  // OBI plug target <-> regif
  logic                 target_obi_req;
  logic                 target_obi_gnt;
  logic [31:0]          target_obi_addr;
  logic                 target_obi_we;
  logic [3:0]           target_obi_be;
  logic [31:0]          target_obi_wdata;
  logic [OpIdWidth-1:0] target_obi_aid;
  logic                 target_obi_rvalid;
  logic                 target_obi_rready;
  logic [31:0]          target_obi_rdata;
  logic                 target_obi_err;
  logic [OpIdWidth-1:0] target_obi_rid;

  redmule_regif__in_t  hwif_in;
  redmule_regif__in_t  hwif_in_target;
  redmule_regif__out_t hwif_out;

  /* HWPE controller target port */
  hwpe_ctrl_target #(
    .NB_CONTEXT            ( 2                                         ),
    .ID_WIDTH              ( OpIdWidth                                 ),
    .ADDR_WIDTH            ( 8                                         ),
    .hwpe_ctrl_regif_in_t  ( redmule_regif__in_t                       ),
    .hwpe_ctrl_regif_out_t ( redmule_regif__out_t                      ),
    .hwpe_ctrl_job_indep_t ( redmule_regif__hwpe_ctrl_job_indep__out_t ),
    .hwpe_ctrl_job_dep_t   ( redmule_regif__hwpe_ctrl_job_dep__out_t   )
  ) i_target (
    .clk_i                ( clk_i              ),
    .rst_ni               ( rst_ni             ),
    .clear_o              ( target_clear_o     ),
    .target               ( target             ),
    .job_trigger_o        ( job_trigger        ),
    .job_done_i           ( job_done           ),
    .job_status_i         ( job_status         ),
    .job_indep_regs_o     ( job_indep_regs     ),
    .job_dep_regs_valid_o ( job_dep_regs_valid ),
    .job_dep_regs_o       ( job_dep_regs       ),
    .target_obi_req_o     ( target_obi_req     ),
    .target_obi_gnt_i     ( target_obi_gnt     ),
    .target_obi_addr_o    ( target_obi_addr    ),
    .target_obi_we_o      ( target_obi_we      ),
    .target_obi_be_o      ( target_obi_be      ),
    .target_obi_wdata_o   ( target_obi_wdata   ),
    .target_obi_aid_o     ( target_obi_aid     ),
    .target_obi_rvalid_i  ( target_obi_rvalid  ),
    .target_obi_rready_o  ( target_obi_rready  ),
    .target_obi_rdata_i   ( target_obi_rdata   ),
    .target_obi_err_i     ( target_obi_err     ),
    .target_obi_rid_i     ( target_obi_rid     ),
    .hwif_in              ( hwif_in_target    ),
    .hwif_out             ( hwif_out           )
  );

  /* RedMulE SystemRDL-generated register interface */
  redmule_regif #(
    .ID_WIDTH ( OpIdWidth )
  ) i_regif (
    .clk          ( clk_i             ),
    .arst_n       ( rst_ni            ),
    .s_obi_req    ( target_obi_req    ),
    .s_obi_gnt    ( target_obi_gnt    ),
    .s_obi_addr   ( target_obi_addr   ),
    .s_obi_we     ( target_obi_we     ),
    .s_obi_be     ( target_obi_be     ),
    .s_obi_wdata  ( target_obi_wdata  ),
    .s_obi_aid    ( target_obi_aid    ),
    .s_obi_rvalid ( target_obi_rvalid ),
    .s_obi_rready ( target_obi_rready ),
    .s_obi_rdata  ( target_obi_rdata  ),
    .s_obi_err    ( target_obi_err    ),
    .s_obi_rid    ( target_obi_rid    ),
    .hwif_in      ( hwif_in           ),
    .hwif_out     ( hwif_out          )
  );

  assign job_done = op_done_i;
  assign config_valid_o = job_trigger;

  always_ff @(posedge clk_i or negedge rst_ni) begin : job_status_trigger
    if(~rst_ni) begin
      job_status <= '0;
    end else begin
      if(clear_i | target_clear_o) begin // Clear job status on external or target-generated clear.
        job_status <= '0;
      end
      else if(job_trigger & config_ready_i) begin
        job_status <= 32'h1;
      end
      else if(op_done_i) begin
        job_status <= '0;
      end
    end
  end

  // Decode instruction and extract configuration parameters from register file values
  assign config_o.m_size          = hwif_out.hwpe_job_dep.mcnfig0.m_size.value;
  assign config_o.n_size          = hwif_out.hwpe_job_dep.mcnfig1.n_size.value;
  assign config_o.k_size          = hwif_out.hwpe_job_dep.mcnfig0.k_size.value;
  assign config_o.receive_x       = hwif_out.hwpe_job_dep.mcnfig1.receive_x.value;
  assign config_o.send_x          = hwif_out.hwpe_job_dep.mcnfig1.send_x.value;
  assign config_o.receive_w       = hwif_out.hwpe_job_dep.mcnfig1.receive_w.value;
  assign config_o.send_w          = hwif_out.hwpe_job_dep.mcnfig1.send_w.value;
  assign config_o.y_offs          = hwif_out.hwpe_job_dep.mcnfig2.y_offs.value;
  assign config_o.x_addr          = hwif_out.hwpe_job_dep.marith0.x_addr.value;
  assign config_o.w_addr          = hwif_out.hwpe_job_dep.marith1.w_addr.value;
  assign config_o.z_addr          = hwif_out.hwpe_job_dep.marith2.z_addr.value;
  assign config_o.gemm_ops        = gemm_op_e'(hwif_out.hwpe_job_dep.mcnfig1.gemm_ops.value);
  assign config_o.gemm_input_fmt  = gemm_fmt_e'(hwif_out.hwpe_job_dep.mcnfig1.gemm_input_fmt.value);
  assign config_o.gemm_output_fmt = gemm_fmt_e'(hwif_out.hwpe_job_dep.mcnfig1.gemm_output_fmt.value);

  // Operation ID counter:
  // op_id_counter_in_q:  Increments when operations are issued (tags for tracking)
  // op_id_counter_out_q: Increments when operations complete (for MOPCNT instruction)
  logic [OpIdWidth-1:0] op_id_counter_in_q, op_id_counter_out_q;

  // Input counter: increments when MARITH instruction is issued
  // Returns this value to CPU as operation ID for software tracking
  always_ff @(posedge clk_i or negedge rst_ni) begin : op_id_counter_in
    if (~rst_ni) begin
      op_id_counter_in_q <= 0;
    end else begin
      if (clear_i | target_clear_o) begin
        op_id_counter_in_q <= 0;
      end else if (job_trigger) begin
        op_id_counter_in_q <= op_id_counter_in_q + 1;
      end
    end
  end

  // Output counter: increments when any operation completes
  // Returns this value for MOPCNT instruction to check completion status
  // Initialized to all 1's to detect first completion (wraps to 0)
  always_ff @(posedge clk_i or negedge rst_ni) begin : op_id_counter_out
    if (~rst_ni) begin
      op_id_counter_out_q <= '1;
    end else begin
      if (clear_i | target_clear_o) begin
        op_id_counter_out_q <= '1;
      end else if (op_done_i) begin
        op_id_counter_out_q <= op_id_counter_out_q + 1;
      end
    end
  end

  // Combine hwif_in from hwpe_ctrl_target with RedMulE-specific fields
  always_comb
  begin
    hwif_in = hwif_in_target;
    hwif_in.hwpe_job_dep.mopcnt.op_id_cnt.next = op_id_counter_out_q;
  end

endmodule: redmule_target_decoder
