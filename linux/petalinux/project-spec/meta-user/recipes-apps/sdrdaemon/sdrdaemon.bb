DESCRIPTION = "SDR daemon NBFM TX test app"
SECTION = "apps"
LICENSE = "CLOSED"

SRC_URI = "file://sdrdaemon.c"

S = "${WORKDIR}"

do_compile() {
    ${CC} ${CFLAGS} ${LDFLAGS} -o sdrdaemon sdrdaemon.c -lm
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 sdrdaemon ${D}${bindir}
}
