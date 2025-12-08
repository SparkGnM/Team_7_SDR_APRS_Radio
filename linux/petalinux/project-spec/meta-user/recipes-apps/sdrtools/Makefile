# Makefile for sdr_tools PetaLinux app

APP_BINARIES = sdr_control rf_tx_test rf_rx_capture

all: $(APP_BINARIES)

sdr_control: sdr_control.c mmio.c sdr_regs.h
	$(CC) $(CFLAGS) -O2 -Wall -o $@ sdr_control.c mmio.c

rf_tx_test: rf_tx_test.c mmio.c sdr_dma.c sdr_regs.h sdr_dma.h
	$(CC) $(CFLAGS) -O2 -Wall -o $@ rf_tx_test.c mmio.c sdr_dma.c

rf_rx_capture: rf_rx_capture.c mmio.c sdr_dma.c sdr_regs.h sdr_dma.h
	$(CC) $(CFLAGS) -O2 -Wall -o $@ rf_rx_capture.c mmio.c sdr_dma.c

clean:
	rm -f $(APP_BINARIES)
