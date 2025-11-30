# Senior_Project
# FPGA – SDR Front-End

This folder contains the custom HDL and constraints for the Team 7 SDR/APRS radio.

## Modules

- `rtl/ad7386_axis_source_1Msps.v`  
  AXI-Stream source wrapper for the AD7386 ADC.
  - SPI input: SCLK, CS#, SDOA
  - Outputs samples as AXIS at 1 MSPS

- `rtl/ad5541_axis_sink_1Msps.v`  
  AXI-Stream sink wrapper for the AD5541 DAC.
  - AXIS input samples at 1 MSPS
  - Outputs SPI: SCLK, CS#, DIN

## Constraints

- `constr/arty_z7_adcdac_pmods.xdc`  
  Maps the ADC/DAC SPI pins to Pmod JA/JB on the Arty Z7-20.

## Vivado Notes

- Project name: `Hack_RF_GNU_Petalinux`
- Top-level block design: `petalinux_build`
- Export hardware as XSA (include bitstream) for PetaLinux.
