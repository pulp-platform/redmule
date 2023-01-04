#include <stdio.h>

// Include common routines
#include <verilated.h>

// Include model header
#include "Vsim_hwpe.h"

// If "verilator --trace" is used, include the tracing class
//#if VM_TRACE
# include <verilated_vcd_c.h>
//#endif

#define CYCLES    1000 
#define CLK_DELAY  200
#define TIMEOUT   100000*CYCLES

// Current simulation time (64-bit unsigned)
vluint64_t main_time = 0;

// Called by $time in Verilog
double sc_time_stamp() {
  return main_time;  // Note does conversion to real, to match SystemC
}

const char *my_getenv(const char *s) {
  return (const char *) getenv(s);
}

int main(int argc, char **argv, char **env) {
  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);
  VerilatedVcdC *tfp = new VerilatedVcdC;
  Vsim_hwpe *top = new Vsim_hwpe;
  top->trace(tfp, 99); // trace 99 levels of hier

  top->enable_i      = 0;
  top->test_mode_i   = 0;
  top->clear_i       = 0;
  top->fetch_enable  = 0;
  top->randomize_mem = 0;
  top->enable_mem    = 1;

  tfp->open("sim.vcd");
  bool flag = false;

  while(!Verilated::gotFinish() && main_time < TIMEOUT) {
    
    if(main_time < 100*CYCLES)
      top->rst_ni = 0;
    else
      top->rst_ni = 1;

    if(main_time < 120*CYCLES) {
      top->clk_i = 0;
      top->clk_delayed_i = 0;
    }
    else {
      if(main_time % (CYCLES/2) == 0)
        top->clk_i = !top->clk_i;

      if((main_time-CLK_DELAY) % (CYCLES/2) == 0)
        top->clk_delayed_i = !top->clk_delayed_i;
    }

    // initial-block
    int id, cnt_rd, cnt_wr;
    
    if(main_time == 280*CYCLES)
      top->fetch_enable = 1;

    top->eval();
    tfp->dump(main_time);
    main_time ++;
  }
  tfp->close();
  printf("main_time=%fns\n", ((double) main_time) / 1000);

  delete top;
  exit(0);
}
