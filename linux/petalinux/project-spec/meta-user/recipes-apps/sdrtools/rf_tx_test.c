// rf_tx_test.c - skeleton RF TX test using DMA0 MM2S

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

    // TODO: choose a real physical address for your TX buffer
    // e.g., a reserved region in device tree.
    uint32_t tx_buf_phys   = 0x1F000000;  // PLACEHOLDER
    uint32_t tx_len_bytes  = 4096;        // e.g. 1024 IQ samples * 4 bytes

    printf("Starting RF TX DMA: buf=0x%08X len=%u bytes\n",
           tx_buf_phys, tx_len_bytes);

    dma_mm2s_simple(&dma_rf, tx_buf_phys, tx_len_bytes);

    printf("RF TX DMA complete\n");

    mmio_close(&dma_rf);
    return 0;
}
