// mmio.h - simple /dev/mem helper for AXI-lite registers
#ifndef MMIO_H
#define MMIO_H

#include <stdint.h>
#include <stddef.h>

typedef struct {
    int      fd;
    void    *base;
    size_t   size;
} mmio_region_t;

// Open /dev/mem and map [phys_addr, phys_addr + size)
int mmio_init(mmio_region_t *r, off_t phys_addr, size_t size);

// Unmap and close
void mmio_close(mmio_region_t *r);

// 32-bit read/write helpers
static inline uint32_t mmio_read32(mmio_region_t *r, off_t offset) {
    volatile uint32_t *ptr = (uint32_t *)((uint8_t *)r->base + offset);
    return *ptr;
}

static inline void mmio_write32(mmio_region_t *r, off_t offset, uint32_t value) {
    volatile uint32_t *ptr = (uint32_t *)((uint8_t *)r->base + offset);
    *ptr = value;
}

#endif // MMIO_H
