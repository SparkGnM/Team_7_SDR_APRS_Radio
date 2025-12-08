// sdr_control.c - basic control utility (GPIO + DMA status)

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include "mmio.h"
#include "sdr_regs.h"

static void usage(const char *prog) {
    fprintf(stderr,
        "Usage: %s <command> [args]\n"
        "\n"
        "Commands:\n"
        "  status          - show switches, LEDs\n"
        "  leds <hex>      - set LED bits (e.g. leds 0x5)\n"
        "  dma_status      - dump DMA0 (RF) and DMA1 (audio) status regs\n"
        "\n",
        prog);
}

static int init_gpio(mmio_region_t *gpio) {
    if (mmio_init(gpio, SDR_GPIO_BASE_PHYS, SDR_GPIO_SPAN) != 0) {
        perror("mmio_init(gpio)");
        return -1;
    }
    // CH1 = input (switches)
    mmio_write32(gpio, GPIO_CH1_TRI_OFFSET, 0xFFFFFFFFu);
    // CH2 = outputs for LEDs on lower bits
    mmio_write32(gpio, GPIO_CH2_TRI_OFFSET, ~SDR_GPIO_LEDS_MASK);
    return 0;
}

static uint32_t gpio_read_switches(mmio_region_t *gpio) {
    uint32_t raw = mmio_read32(gpio, GPIO_CH1_DATA_OFFSET);
    return raw & SDR_GPIO_SWS_MASK;
}

static uint32_t gpio_read_leds(mmio_region_t *gpio) {
    uint32_t raw = mmio_read32(gpio, GPIO_CH2_DATA_OFFSET);
    return raw & SDR_GPIO_LEDS_MASK;
}

static void gpio_write_leds(mmio_region_t *gpio, uint32_t value) {
    uint32_t v = value & SDR_GPIO_LEDS_MASK;
    mmio_write32(gpio, GPIO_CH2_DATA_OFFSET, v);
}

static void dump_dma_status(const char *name, off_t base_phys) {
    mmio_region_t dma;
    if (mmio_init(&dma, base_phys, SDR_DMA_SPAN) != 0) {
        fprintf(stderr, "Failed to map %s @ 0x%08lx\n",
                name, (unsigned long)base_phys);
        return;
    }

    uint32_t mm2s_dmacr = mmio_read32(&dma, DMA_MM2S_DMACR);
    uint32_t mm2s_dmasr = mmio_read32(&dma, DMA_MM2S_DMASR);
    uint32_t s2mm_dmacr = mmio_read32(&dma, DMA_S2MM_DMACR);
    uint32_t s2mm_dmasr = mmio_read32(&dma, DMA_S2MM_DMASR);

    printf("%s (base 0x%08lx):\n", name, (unsigned long)base_phys);
    printf("  MM2S_DMACR = 0x%08X\n", mm2s_dmacr);
    printf("  MM2S_DMASR = 0x%08X\n", mm2s_dmasr);
    printf("  S2MM_DMACR = 0x%08X\n", s2mm_dmacr);
    printf("  S2MM_DMASR = 0x%08X\n", s2mm_dmasr);

    mmio_close(&dma);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        usage(argv[0]);
        return 1;
    }

    const char *cmd = argv[1];

    if (strcmp(cmd, "dma_status") == 0) {
        dump_dma_status("DMA_RF (axi_dma_0)", SDR_DMA_RF_BASE_PHYS);
        dump_dma_status("DMA_AUDIO (axi_dma_1)", SDR_DMA_AUDIO_BASE_PHYS);
        return 0;
    }

    mmio_region_t gpio;
    if (init_gpio(&gpio) != 0) {
        return 1;
    }

    if (strcmp(cmd, "status") == 0) {
        uint32_t sws  = gpio_read_switches(&gpio);
        uint32_t leds = gpio_read_leds(&gpio);

        printf("Switches: 0x%08X\n", sws);
        printf("LEDs    : 0x%08X\n", leds);

    } else if (strcmp(cmd, "leds") == 0) {
        if (argc < 3) {
            fprintf(stderr, "leds command requires <hex_value>\n");
            usage(argv[0]);
            mmio_close(&gpio);
            return 1;
        }
        uint32_t value = (uint32_t)strtoul(argv[2], NULL, 0);
        gpio_write_leds(&gpio, value);
        printf("LEDs set to 0x%X\n", value & SDR_GPIO_LEDS_MASK);

    } else {
        usage(argv[0]);
        mmio_close(&gpio);
        return 1;
    }

    mmio_close(&gpio);
    return 0;
}
