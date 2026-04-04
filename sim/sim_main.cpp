#include "Vtb.h"
#include "verilated.h"
#include <cstdio>

static void tick(Vtb* top) {
    top->clk_i ^= 1;
    top->eval();
}

static void run_cycles(Vtb* top, int n) {
    for (int i = 0; i < n; i++) {
        tick(top);  // rising edge
        tick(top);  // falling edge
    }
}

int main(int argc, char** argv) {
    VerilatedContext* ctx = new VerilatedContext;
    ctx->commandArgs(argc, argv);

    Vtb* top = new Vtb{ctx};

    // Initial state
    top->clk_i  = 0;
    top->rst_ni = 1;
    top->eval();

    // Settle before reset
    run_cycles(top, 5);

    // Assert reset for 20 cycles
    top->rst_ni = 0;
    run_cycles(top, 20);

    // Deassert reset
    top->rst_ni = 1;
    run_cycles(top, 10);

    // Run until core_sleep_o (WFI) or timeout
    const int TIMEOUT = 50000;
    int cycle = 0;
    while (!top->core_sleep_o && cycle < TIMEOUT) {
        tick(top);
        tick(top);
        cycle++;
    }

    if (top->core_sleep_o) {
        printf("PASS: core reached WFI after %d cycles\n", cycle);
    } else {
        printf("FAIL: timeout after %d cycles\n", TIMEOUT);
    }

    int rc = top->core_sleep_o ? 0 : 1;
    top->final();
    delete top;
    delete ctx;
    return rc;
}
