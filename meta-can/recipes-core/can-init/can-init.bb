SUMMARY = "Startup script to enable CAN0 interface"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=600c59a28241704845af9fa4dc6fae77"

SRC_URI = "file://S40can0 \
           file://LICENSE"


S = "${WORKDIR}"

do_install() {
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/S40can0 ${D}${sysconfdir}/init.d/
}

FILES:${PN} += "${sysconfdir}/init.d/S40can0"
