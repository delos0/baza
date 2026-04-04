CROSS   := riscv64-unknown-elf
CORE    := hw/cv32e40p/rtl
BHV     := hw/cv32e40p/bhv

SV_FILES := \
  $(shell find $(CORE)/include $(CORE) -maxdepth 1 -name "*.sv" ! -name "*fp_wrapper*") \
  $(BHV)/cv32e40p_sim_clock_gate.sv \
  hw/obi_pkg.sv \
  hw/pulp_platform/tech_cells_generic/src/rtl/tc_clk.sv \
  hw/pulp_platform/tech_cells_generic/src/rtl/tc_sram.sv \
  hw/pulp_platform/common_cells/src/rstgen_bypass.sv \
  hw/sram_wrapper.sv hw/sram_obi_wrap.sv hw/cpu_subsystem.sv hw/soc_top.sv \
  sim/tb.sv

INCS := +incdir+$(CORE)/include +incdir+$(BHV) +incdir+$(BHV)/include

sw/firmware.hex: sw/start.S sw/link.ld
	$(CROSS)-gcc -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles \
	  -T sw/link.ld sw/start.S -o sw/firmware.elf
	$(CROSS)-objcopy -O verilog --verilog-data-width 4 sw/firmware.elf $@

obj_dir/Vtb: sw/firmware.hex $(SV_FILES) sim/sim_main.cpp
	verilator --cc --exe --top-module tb --Mdir obj_dir \
	  --no-timing -Wall -Wno-fatal -Wno-BLKANDNBLK \
	  $(INCS) $(SV_FILES) sim/sim_main.cpp
	$(MAKE) -C obj_dir -f Vtb.mk

.PHONY: sim clean
sim: obj_dir/Vtb
	obj_dir/Vtb

clean:
	rm -rf obj_dir sw/firmware.elf sw/firmware.hex
