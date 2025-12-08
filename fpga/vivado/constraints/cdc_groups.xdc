## ============================================================
## Clock domain crossing: PS system clock vs audio clock
## Treat clk_fpga_0 and clk_out1_petalinux_build_clk_wiz_0_0
## as asynchronous so Vivado does not time paths between them.
## The AXI I2S IP handles the CDC internally.
## ============================================================
set_clock_groups -asynchronous \
    -group [get_clocks { clk_fpga_0 }] \
    -group [get_clocks { clk_out1_petalinux_build_clk_wiz_0_0 }]


