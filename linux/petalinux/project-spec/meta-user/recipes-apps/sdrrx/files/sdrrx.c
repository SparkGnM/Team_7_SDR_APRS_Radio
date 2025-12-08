#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>

// ---------- Addresses: ADJUST IF NEEDED ----------
#define DMA_RF_BASE_PHYS    0x40400000U   // AXI DMA 0 base (RF TX/RX)
#define DMA_RF_SPAN         0x00010000U   // 64 KB

// RX buffer in DDR
#define RX_BUF_PHYS         0x1F100000U   // scratch DDR region for RX
#define RX_BUF_SIZE_BYTES   (64 * 1024)   // 64 KB

// AXI DMA S2MM (Rx) register offsets
#define S2MM_DMACR   0x30
#define S2MM_DMASR   0x34
#define S2MM_DA      0x48
#define S2MM_LENGTH  0x58

// Control bits
#define DMACR_RUNSTOP   (1u << 0)
#define DMACR_RESET     (1u << 2)
#define DMASR_IOC_IRQ   (1u << 12)
#define DMASR_ERR_IRQ   (1u << 14)

static void* map_region(off_t phys, size_t size)
{
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) { perror("open(/dev/mem)"); return NULL; }

    void *base = mmap(NULL, size, PROT_READ | PROT_WRITE,
                      MAP_SHARED, fd, phys);
    close(fd);

    if (base == MAP_FAILED) { perror("mmap"); return NULL; }
    return base;
}

int main(void)
{
    printf("\n=============================\n");
    printf(" SDR RX CAPTURE (8-bit IQ)\n");
    printf(" Using DMA0 S2MM -> DDR\n");
    printf(" Buffer: 0x%08X, %u bytes\n", RX_BUF_PHYS, RX_BUF_SIZE_BYTES);
    printf("=============================\n\n");

    volatile uint32_t *dma = (volatile uint32_t *) map_region(DMA_RF_BASE_PHYS, DMA_RF_SPAN);
    if (!dma) {
        fprintf(stderr, "Failed to map DMA RF registers\n");
        return 1;
    }

    volatile uint32_t *rxbuf = (volatile uint32_t *) map_region(RX_BUF_PHYS, RX_BUF_SIZE_BYTES);
    if (!rxbuf) {
        fprintf(stderr, "Failed to map RX buffer\n");
        return 1;
    }

    // Optionally clear buffer
    for (uint32_t i = 0; i < RX_BUF_SIZE_BYTES / 4; ++i) {
        rxbuf[i] = 0;
    }

    // Reset S2MM
    dma[S2MM_DMACR / 4] = DMACR_RESET;
    usleep(1000);

    // Clear status
    dma[S2MM_DMASR / 4] = 0xFFFFFFFFu;

    // Set destination address
    dma[S2MM_DA / 4] = RX_BUF_PHYS;

    // Run channel
    dma[S2MM_DMACR / 4] = DMACR_RUNSTOP;

    printf("Starting RX capture via DMA0 S2MM...\n");

    // Single transfer
    dma[S2MM_LENGTH / 4] = RX_BUF_SIZE_BYTES;

    // Wait for completion
    while (1) {
        uint32_t status = dma[S2MM_DMASR / 4];
        if (status & DMASR_ERR_IRQ) {
            printf("DMA ERROR: S2MM_DMASR=0x%08X\n", status);
            dma[S2MM_DMASR / 4] = status;
            return 1;
        }
        if (status & DMASR_IOC_IRQ) {
            printf("Capture complete. S2MM_DMASR=0x%08X\n", status);
            dma[S2MM_DMASR / 4] = DMASR_IOC_IRQ; // clear IOC
            break;
        }
        usleep(1000);
    }

    // Write 8-bit IQ to file
    const char *fname = "/tmp/rx_iq.bin";
    FILE *f = fopen(fname, "wb");
    if (!f) {
        perror("fopen(/tmp/rx_iq.bin)");
        return 1;
    }

    uint32_t samples32 = RX_BUF_SIZE_BYTES / 4; // # of 32-bit words
    size_t out_count = 0;

    for (uint32_t i = 0; i < samples32; ++i) {
        uint32_t w = rxbuf[i];
        uint16_t packed16 = (uint16_t)(w & 0xFFFF);

        int8_t i8 = (int8_t)(packed16 >> 8);   // I in upper byte
        int8_t q8 = (int8_t)(packed16 & 0xFF); // Q in lower byte

        fwrite(&i8, 1, 1, f);
        fwrite(&q8, 1, 1, f);
        out_count += 2;
    }

    fclose(f);

    printf("Wrote %zu bytes to %s\n", out_count, fname);
    printf("Each sample: 2 bytes [I8, Q8] signed, interleaved.\n");

    return 0;
}
