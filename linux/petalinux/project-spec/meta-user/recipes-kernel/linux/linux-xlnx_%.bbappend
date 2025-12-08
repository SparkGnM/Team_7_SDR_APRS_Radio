FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://bsp.cfg"
KERNEL_FEATURES:append = " bsp.cfg"
SRC_URI += "file://user_2025-11-30-00-39-00.cfg \
            file://user_2025-11-30-03-13-00.cfg \
            file://user_2025-12-04-11-55-00.cfg \
            "

