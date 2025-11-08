# sound-sensor_1.0.bb
SUMMARY = "Simple sound sensor test program"
DESCRIPTION = "C program to read digital sound sensor on Raspberry Pi using libgpiod"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://CMakeLists.txt \
           file://sound_detect.c"

S = "${WORKDIR}"

DEPENDS = "libgpiod cmake-native pkgconfig-native"

inherit cmake

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/sound_detect ${D}${bindir}/
}
