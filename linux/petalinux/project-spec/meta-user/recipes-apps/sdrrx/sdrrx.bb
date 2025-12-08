DESCRIPTION = "Simple SDR RX capture app (8-bit IQ)"
SECTION = "apps"
LICENSE = "CLOSED"

SRC_URI = "file://sdrrx.c"

S = "${WORKDIR}"

do_compile() {
    ${CC} ${CFLAGS} ${LDFLAGS} -o sdrrx sdrrx.c
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 sdrrx ${D}${bindir}
}
