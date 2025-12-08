// rf_rx_capture.c - skeleton RF RX capture using DMA0 S2MM

#include <stdio.h>
#include <stdint.h>
#include "mmio.h"
#include "sdr_regs.h"
#include "sdr_dma.h"

int main(void) {
    mmio_region_t dma_rf;

    if (dma_region_init(&dma_rf, SDR_DMA_RF_BASE_PHYS) != 0) {
        fprintf(stderr, "Failed to init RF DMA\n");
        return 1;
    }

    // TODO: choose a real physical address for your RX buffer
    uint32_t rx_buf_phys   = 0x1F001000;  // PLACEHOLDER
    uint32_t rx_len_bytes  = 4096;

    printf("Starting RF RX DMA: buf=0x%08X len=%u bytes\n",
           rx_buf_phys, rx_len_bytes);

    dma_s2mm_simple(&dma_rf, rx_buf_phys, rx_len_bytes);

    printf("RF RX DMA complete\n");

    mmio_close(&dma_rf);
    return 0;
}
