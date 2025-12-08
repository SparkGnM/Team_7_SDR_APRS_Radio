// sdr_regs.h - SDR register map for current hardware
#ifndef SDR_REGS_H
#define SDR_REGS_H

#include <stdint.h>

//
// AXI GPIO (axi_gpio_0) @ 0x4120_0000
//
#define SDR_GPIO_BASE_PHYS        0x41200000U
#define SDR_GPIO_SPAN             0x00010000U  // 64 KB

// Standard Xilinx GPIO register offsets
#define GPIO_CH1_DATA_OFFSET      0x00U
#define GPIO_CH1_TRI_OFFSET       0x04U
#define GPIO_CH2_DATA_OFFSET      0x08U
#define GPIO_CH2_TRI_OFFSET       0x0CU

// Channel usage:
//  CH1 -> switches (inputs)
//  CH2 -> LEDs (outputs)
#define SDR_GPIO_SWS_MASK         0x00000003U   // 2 switches
#define SDR_GPIO_LEDS_MASK        0x0000000FU   // 4 LEDs

//
// AXI DMA 0 (RF path) @ 0x4040_0000
//
#define SDR_DMA_RF_BASE_PHYS      0x40400000U
#define SDR_DMA_SPAN              0x00010000U  // 64 KB

//
// AXI DMA 1 (Audio path) @ 0x4041_0000
//
#define SDR_DMA_AUDIO_BASE_PHYS   0x40410000U

// AXI DMA register offsets (same for both DMAs)
#define DMA_MM2S_DMACR            0x00
#define DMA_MM2S_DMASR            0x04
#define DMA_MM2S_SA               0x18
#define DMA_MM2S_LENGTH           0x28

#define DMA_S2MM_DMACR            0x30
#define DMA_S2MM_DMASR            0x34
#define DMA_S2MM_DA               0x48
#define DMA_S2MM_LENGTH           0x58

// DMACR bits
#define DMA_DMACR_RUNSTOP         (1u << 0)
#define DMA_DMACR_RESET           (1u << 2)

// DMASR bits
#define DMA_DMASR_HALTED          (1u << 0)
#define DMA_DMASR_IDLE            (1u << 1)
#define DMA_DMASR_IOC_IRQ         (1u << 12)
#define DMA_DMASR_ERR_IRQ         (1u << 14)

//
// AXI I2S core (axi_i2s_adi_0) @ 0x43C0_0000
// (not used yet, address here for when you want it)
//
#define SDR_I2S_BASE_PHYS         0x43C00000U
#define SDR_I2S_SPAN              0x00010000U

#endif // SDR_REGS_H
