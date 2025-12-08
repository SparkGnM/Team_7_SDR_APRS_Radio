## ============================================================
## Hack_RF_GNU_Petalinux - Master Constraints
## Target: Arty Z7-20
## ============================================================

## ------------------------------------------------------------
## 0. System clock (PL) - unused as external pin in this design
##    Leave commented unless you actually bring clk in as a port.
## ------------------------------------------------------------
## set_property -dict { PACKAGE_PIN H16 IOSTANDARD LVCMOS33 } [get_ports { clk }];
## create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];

## ============================================================
## 1. On-board LEDs (4) - driven by AXI GPIO (leds_4bits[3:0])
## ============================================================
## If your wrapper uses a different name (e.g. leds_4bits_tri_o),
## change the get_ports name to match.
##set_property -dict { PACKAGE_PIN R14 IOSTANDARD LVCMOS33 } [get_ports { leds_4bits[0] }]; # LED0
##set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports { leds_4bits[1] }]; # LED1
##set_property -dict { PACKAGE_PIN N16 IOSTANDARD LVCMOS33 } [get_ports { leds_4bits[2] }]; # LED2
##set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 } [get_ports { leds_4bits[3] }]; # LED3

## Buttons on Arty Z7-20
## BTN0 (D19) -> btns_0[0]  (freq down)
## BTN1 (D20) -> btns_0[1]  (freq up)
## BTN2 (L20) -> ptt_btn_0  (push-to-talk)

set_property -dict { PACKAGE_PIN D19 IOSTANDARD LVCMOS33 } [get_ports { btns_0[0] }];
set_property -dict { PACKAGE_PIN D20 IOSTANDARD LVCMOS33 } [get_ports { btns_0[1] }];
set_property -dict { PACKAGE_PIN L20 IOSTANDARD LVCMOS33 } [get_ports { ptt_btn_0 }];

## ============================================================
## 3. Slide switches (SW0..SW1) - on AXI GPIO second channel
##    External BD port: sws_2bits[1:0]  (change name if needed)
##
## From Arty Z7-20 master XDC:
##   SW0 -> M20
##   SW1 -> M19
## ============================================================

##set_property -dict { PACKAGE_PIN M20 IOSTANDARD LVCMOS33 } [get_ports { sws_2bits[0] }]; # SW0
##set_property -dict { PACKAGE_PIN M19 IOSTANDARD LVCMOS33 } [get_ports { sws_2bits[1] }]; # SW1


## ============================================================
## 4. Audio / I2S on Pmod JA (P pins only)
##    Using JA1_P..JA4_P for BCLK, LRCLK, SDATA_O, SDATA_I
##
## JA1_P -> BCLK_O_0[0]
## JA2_P -> LRCLK_O_0[0]
## JA3_P -> SDATA_O_0[0] (I2S out)
## JA4_P -> SDATA_I_0[0] (I2S in)
## ============================================================
set_property -dict { PACKAGE_PIN Y18 IOSTANDARD LVCMOS33 } [get_ports { BCLK_O_0[0] }];   # JA1_P
set_property -dict { PACKAGE_PIN Y16 IOSTANDARD LVCMOS33 } [get_ports { LRCLK_O_0[0] }];  # JA2_P
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports { SDATA_O_0[0] }];  # JA3_P
set_property -dict { PACKAGE_PIN W18 IOSTANDARD LVCMOS33 } [get_ports { SDATA_I_0[0] }];  # JA4_P

## ============================================================
## 5. ADC (AD7386) SPI - on ChipKit header
##    External BD ports: adc_sclk_0, adc_cs_n_0, adc_sdoa_0
##    Pins use ck_io0..2 from the master XDC
## ============================================================
set_property -dict { PACKAGE_PIN T14 IOSTANDARD LVCMOS33 } [get_ports { adc_sclk_0 }];  # ck_io0
set_property -dict { PACKAGE_PIN U12 IOSTANDARD LVCMOS33 } [get_ports { adc_cs_n_0 }];  # ck_io1
set_property -dict { PACKAGE_PIN U13 IOSTANDARD LVCMOS33 } [get_ports { adc_sdoa_0 }];  # ck_io2 (MISO)

## ============================================================
## 6. DAC (AD5541) SPI - on ChipKit header
##    External BD ports: dac_cs_n_0, dac_sclk_0, dac_din_0
##    Pins use ck_io3..5 from the master XDC
## ============================================================
set_property -dict { PACKAGE_PIN V13 IOSTANDARD LVCMOS33 } [get_ports { dac_din_0 }];   # ck_io3 (MOSI)
set_property -dict { PACKAGE_PIN V15 IOSTANDARD LVCMOS33 } [get_ports { dac_cs_n_0 }];  # ck_io4 (CS_n)
set_property -dict { PACKAGE_PIN T15 IOSTANDARD LVCMOS33 } [get_ports { dac_sclk_0 }];  # ck_io5 (SCLK)

## ============================================================
## 7. Digital Pot (MCP41HV51) SPI - on ChipKit header
##    External BD ports: pot_cs_n_0, pot_sck_0, pot_mosi_0
##    Pins use ck_io6..8 from the master XDC
## ============================================================
set_property -dict { PACKAGE_PIN R16 IOSTANDARD LVCMOS33 } [get_ports { pot_sck_0 }];    # ck_io6 (SCK)
set_property -dict { PACKAGE_PIN U17 IOSTANDARD LVCMOS33 } [get_ports { pot_cs_n_0 }];   # ck_io7 (CS_n)
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports { pot_mosi_0 }];   # ck_io8 (MOSI)

## ============================================================
## End of master constraints
## ============================================================
