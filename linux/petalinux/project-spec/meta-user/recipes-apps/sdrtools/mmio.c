// mmio.c
#include "mmio.h"
#include <fcntl.h>
#include <stdio.h>
#include <sys/mman.h>
#include <unistd.h>

int mmio_init(mmio_region_t *r, off_t phys_addr, size_t size) {
    r->fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (r->fd < 0) {
        perror("open(/dev/mem)");
        return -1;
    }

    r->base = mmap(NULL, size, PROT_READ | PROT_WRITE,
                   MAP_SHARED, r->fd, phys_addr);
    if (r->base == MAP_FAILED) {
        perror("mmap");
        close(r->fd);
        r->fd = -1;
        return -1;
    }

    r->size = size;
    return 0;
}

void mmio_close(mmio_region_t *r) {
    if (r->base && r->base != MAP_FAILED) {
        munmap(r->base, r->size);
        r->base = NULL;
    }
    if (r->fd >= 0) {
        close(r->fd);
        r->fd = -1;
    }
}
