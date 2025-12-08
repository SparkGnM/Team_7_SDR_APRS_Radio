DESCRIPTION = "Simple SDR tools test app"
SECTION = "apps"
LICENSE = "CLOSED"

SRC_URI = "file://sdr_tools.c"

S = "${WORKDIR}"

do_compile() {
    ${CC} ${CFLAGS} ${LDFLAGS} -o sdr_tools sdr_tools.c
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 sdr_tools ${D}${bindir}
}
