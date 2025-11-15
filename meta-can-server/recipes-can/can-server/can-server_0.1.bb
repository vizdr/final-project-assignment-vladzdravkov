SUMMARY = "CAN Socket Sender Application"
DESCRIPTION = "Reads detection count from a file and sends it over CAN using SocketCAN"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "git://github.com/vizdr/final-project-assignment-app-vizdr.git;protocol=ssh;branch=master"
SRCREV = "144113df75627c4835668e4544b9ae9ebbd4b8a2"

S = "${WORKDIR}/git/Socket_CAN_Sender"

SRC_URI += "file://S99can-server"

inherit cmake update-rc.d
INITSCRIPT_NAME = "can-server"
INITSCRIPT_PARAMS = "defaults 99"

# Optionally can be set CMake options
EXTRA_OECMAKE = ""

do_install() {
    # Install binary
    install -d ${D}${bindir}
    install -m 0755 ${B}/can_send_detection ${D}${bindir}/

    # Install init script as S99can-server (renamed to can-server)
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/S99can-server ${D}${sysconfdir}/init.d/can-server
}

FILES_${PN} = "\
    ${bindir}/can_send_detection \
    ${sysconfdir}/init.d/can-server \
"