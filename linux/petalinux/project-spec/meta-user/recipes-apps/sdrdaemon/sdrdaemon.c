#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <math.h>

// ---------- Addresses: ADJUST IF NEEDED ----------
#define DMA_RF_BASE_PHYS   0x40400000U   // AXI DMA 0 base (RF TX/RX)
#define DMA_RF_SPAN        0x00010000U   // 64 KB mapped window

// TX buffer in DDR
#define TX_BUF_PHYS        0x1F000000U   // scratch DDR (ensure it's unused)
#define TX_BUF_SIZE_BYTES  (16 * 1024)   // 16 KB -> 4096 complex samples

// AXI DMA MM2S (TX) offsets
#define MM2S_DMACR   0x00
#define MM2S_DMASR   0x04
#define MM2S_SA      0x18
#define MM2S_LENGTH  0x28

// Flags
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
    printf("\n=====================================\n");
    printf(" SDRDAEMON — NBFM 1 kHz TX (8-bit IQ)\n");
    printf(" Fs_RF = 1 MHz (FIR out)\n");
    printf(" Fs_audio = 50 kHz, f_audio = 1 kHz\n");
    printf(" Deviation ≈ 5 kHz\n");
    printf("=====================================\n\n");

    volatile uint32_t *dma = (volatile uint32_t *) map_region(DMA_RF_BASE_PHYS, DMA_RF_SPAN);
    if (!dma) {
        fprintf(stderr, "Failed to map DMA RF registers\n");
        return 1;
    }

    volatile uint32_t *txbuf = (volatile uint32_t *) map_region(TX_BUF_PHYS, TX_BUF_SIZE_BYTES);
    if (!txbuf) {
        fprintf(stderr, "Failed to map TX buffer\n");
        return 1;
    }

    // --- NBFM parameters ---
    const double Fs_rf   = 1000000.0;  // 1 MHz after FIR x5
    const double Fs_aud  = 50000.0;    // 50 kHz audio
    const double f_tone  = 1000.0;     // 1 kHz audio tone
    const double f_dev   = 5000.0;     // 5 kHz deviation
    const int    UPSAMPLE = (int)(Fs_rf / Fs_aud); // expect 20

    if (UPSAMPLE <= 0 || (double)UPSAMPLE * Fs_aud != Fs_rf) {
        printf("ERROR: Fs_rf/Fs_aud is not integer. UPSAMPLE=%d\n", UPSAMPLE);
        return 1;
    }

    printf("Upsample factor (RF / audio) = %d\n", UPSAMPLE);

    // One period of 1 kHz at 50 kHz = 50 samples
    const int N_AUDIO = 50;
    double audio[N_AUDIO];
    for (int n = 0; n < N_AUDIO; ++n) {
        double t = (double)n / Fs_aud;
        audio[n] = sin(2.0 * M_PI * f_tone * t);  // [-1,1]
    }

    uint32_t words = TX_BUF_SIZE_BYTES / 4;
    printf("Filling TX buffer at 0x%08X with NBFM waveform (%u samples)...\n",
           TX_BUF_PHYS, words);

    double phase = 0.0;
    const double K = 2.0 * M_PI * f_dev / Fs_rf;  // phase scale
    int aud_idx = 0;
    int up_ctr  = 0;

    for (uint32_t i = 0; i < words; ++i) {
        double m = audio[aud_idx];   // audio in [-1,1]

        phase += K * m;
        if (phase >  M_PI) phase -= 2.0 * M_PI;
        if (phase < -M_PI) phase += 2.0 * M_PI;

        // NBFM baseband: I = cos(phase), Q = sin(phase)
        double i_f = cos(phase);
        double q_f = sin(phase);

        // Quantize to signed 8-bit [-128,127]
        int8_t i8 = (int8_t)(127.0 * i_f);
        int8_t q8 = (int8_t)(127.0 * q_f);

        // Pack as [I(7:0), Q(7:0)] in lower 16 bits
        uint16_t packed16 = ((uint16_t)(uint8_t)i8 << 8) | (uint8_t)q8;

        txbuf[i] = (uint32_t)packed16;

        // Upsample: repeat each audio sample UPSAMPLE times
        if (++up_ctr >= UPSAMPLE) {
            up_ctr = 0;
            aud_idx++;
            if (aud_idx >= N_AUDIO) aud_idx = 0;
        }
    }

    // --- Configure MM2S ---
    dma[MM2S_DMACR / 4] = DMACR_RESET;
    usleep(1000);
    dma[MM2S_DMASR / 4] = 0xFFFFFFFFu;

    dma[MM2S_SA / 4] = TX_BUF_PHYS;
    dma[MM2S_DMACR / 4] = DMACR_RUNSTOP;

    printf("Streaming NBFM 1 kHz tone via DMA0 MM2S.\n");
    printf("Press PTT (wired in Vivado) to actually transmit RF.\n");

    while (1) {
        dma[MM2S_LENGTH / 4] = TX_BUF_SIZE_BYTES;

        uint32_t status;
        do {
            status = dma[MM2S_DMASR / 4];
            if (status & DMASR_ERR_IRQ) {
                printf("DMA ERROR: MM2S_DMASR=0x%08X\n", status);
                dma[MM2S_DMASR / 4] = status;
                break;
            }
        } while (!(status & DMASR_IOC_IRQ));

        dma[MM2S_DMASR / 4] = DMASR_IOC_IRQ;
    }

    return 0;
}
