# Workaround for broken git fetch of cracklib in 2023.1:
# use the official 2.9.8 release tarball instead.

SRC_URI = "https://github.com/cracklib/cracklib/releases/download/v${PV}/cracklib-${PV}.tar.bz2"
SRC_URI[sha256sum] = "1f9d34385ea3aa7cd7c07fa388dc25810aea9d3c33e260c713a3a5873d70e386"

# Tell bitbake where the extracted sources live (tarball unpack dir)
S = "${WORKDIR}/cracklib-${PV}"
