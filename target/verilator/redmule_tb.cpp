// Verilator Example
// Norbertas Kremeris 2021
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <exception>
#include <cstdio>
#include <cstdint>
#include <cerrno>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vredmule_tb.h"

vluint64_t sim_time = 0;

void dut_reset (Vredmule_tb *dut, vluint64_t &sim_time, vluint64_t rst_time, vluint64_t rst_cycles){
  dut->rst_ni = 0;
  if(sim_time > rst_time && sim_time < rst_time + rst_cycles)
    dut->rst_ni = 1;

  if(sim_time > rst_time + rst_cycles && sim_time < rst_time + 2*rst_cycles)
    dut->rst_ni = 0;
  
  if(sim_time > rst_time + 2*rst_cycles)
    dut->rst_ni = 1;
}

void dut_set_fetch_en (Vredmule_tb *dut, vluint64_t &sim_time, bool value){
  dut->fetch_enable_i = 0;
  if(sim_time > 100){
      dut->fetch_enable_i = value;
  }
}

int main(int argc, char** argv, char** env) {
  // Random values used to initialize signals
  Verilated::commandArgs(argc, argv);
	Vredmule_tb *dut = new Vredmule_tb;

  Verilated::traceEverOn(true);
  VerilatedVcdC *m_trace = new VerilatedVcdC;
	dut->trace(m_trace, 5);
	m_trace->open("waveform.vcd");

	while (!Verilated::gotFinish()) {
    // Reset DUT
    dut_reset(dut, sim_time, 20, 10);
    // Start clock toggling
		dut->clk_i ^= 1;
    // Set fetch enable to core
    dut_set_fetch_en(dut, sim_time, 1);
		dut->eval();
		m_trace->dump(sim_time);
		sim_time++;
	}

	m_trace->close();
	delete dut;
	exit(EXIT_SUCCESS);
}
