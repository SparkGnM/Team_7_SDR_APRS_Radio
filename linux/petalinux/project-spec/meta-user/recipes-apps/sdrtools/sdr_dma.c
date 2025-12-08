// sdr_dma.c
#include "sdr_dma.h"
#include <stdio.h>
#include <unistd.h>

void dma_mm2s_simple(mmio_region_t *dma_regs, uint32_t src_phys, uint32_t length_bytes) {
    // Reset channel
    mmio_write32(dma_regs, DMA_MM2S_DMACR, DMA_DMACR_RESET);
    usleep(10);
    // Clear status
    mmio_write32(dma_regs, DMA_MM2S_DMASR, 0xFFFFFFFFu);

    // Set source address
    mmio_write32(dma_regs, DMA_MM2S_SA, src_phys);

    // Start
    mmio_write32(dma_regs, DMA_MM2S_DMACR, DMA_DMACR_RUNSTOP);

    // Length
    mmio_write32(dma_regs, DMA_MM2S_LENGTH, length_bytes);

    // Poll for IOC
    while (!(mmio_read32(dma_regs, DMA_MM2S_DMASR) & DMA_DMASR_IOC_IRQ)) {
        // busy-wait
    }

    // Clear IOC flag
    mmio_write32(dma_regs, DMA_MM2S_DMASR, DMA_DMASR_IOC_IRQ);
}

void dma_s2mm_simple(mmio_region_t *dma_regs, uint32_t dst_phys, uint32_t length_bytes) {
    mmio_write32(dma_regs, DMA_S2MM_DMACR, DMA_DMACR_RESET);
    usleep(10);
    mmio_write32(dma_regs, DMA_S2MM_DMASR, 0xFFFFFFFFu);

    mmio_write32(dma_regs, DMA_S2MM_DA, dst_phys);

    mmio_write32(dma_regs, DMA_S2MM_DMACR, DMA_DMACR_RUNSTOP);

    mmio_write32(dma_regs, DMA_S2MM_LENGTH, length_bytes);

    while (!(mmio_read32(dma_regs, DMA_S2MM_DMASR) & DMA_DMASR_IOC_IRQ)) {
        // busy-wait
    }

    mmio_write32(dma_regs, DMA_S2MM_DMASR, DMA_DMASR_IOC_IRQ);
}
