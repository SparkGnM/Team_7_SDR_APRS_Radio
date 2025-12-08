// sdr_dma.h - simple blocking DMA helpers for user space
#ifndef SDR_DMA_H
#define SDR_DMA_H

#include <stdint.h>
#include "mmio.h"
#include "sdr_regs.h"

// Initialize a DMA region (RF or audio) using its base phys
static inline int dma_region_init(mmio_region_t *dma_regs, off_t base_phys) {
    return mmio_init(dma_regs, base_phys, SDR_DMA_SPAN);
}

// Simple blocking MM2S transfer
void dma_mm2s_simple(mmio_region_t *dma_regs, uint32_t src_phys, uint32_t length_bytes);

// Simple blocking S2MM transfer
void dma_s2mm_simple(mmio_region_t *dma_regs, uint32_t dst_phys, uint32_t length_bytes);

#endif // SDR_DMA_H
