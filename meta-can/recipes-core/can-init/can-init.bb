# Start in runlevels 2,3,4,5 (normal multi-user)
# Stop in runlevels 0,1,6 (halt, single-user, reboot)
# Priority 20 for start and 80 for stop

SUMMARY = "Startup script to enable CAN0 interface"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=600c59a28241704845af9fa4dc6fae77"

SRC_URI = "file://S40can0 \
           file://LICENSE"

inherit update-rc.d

S = "${WORKDIR}"

INITSCRIPT_NAME = "S40can0"
INITSCRIPT_PARAMS = "start 20 2 3 4 5 . stop 80 0 1 6 ."

do_install() {
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/S40can0 ${D}${sysconfdir}/init.d/
}

FILES:${PN} += "${sysconfdir}/init.d/S40can0"
