################################################################################
# quartus image

FROM ubuntu:25.04 as fpga_install

ARG QUARTUS_MAJOR_VERSION=24.1
ARG QUARTUS_MINOR_VERSION=0
ARG QUARTUS_REVISION_VERSION=1077
ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /tmp

ARG INTEL_CDN="https://downloads.intel.com/akdlm/software/acdsinst"

# Download and install Quartus
ADD ${INTEL_CDN}/${QUARTUS_MAJOR_VERSION}std/${QUARTUS_REVISION_VERSION}/ib_installers/QuartusLiteSetup-${QUARTUS_MAJOR_VERSION}std.${QUARTUS_MINOR_VERSION}.${QUARTUS_REVISION_VERSION}-linux.run .
ADD ${INTEL_CDN}/${QUARTUS_MAJOR_VERSION}std/${QUARTUS_REVISION_VERSION}/ib_installers/cyclone-${QUARTUS_MAJOR_VERSION}std.${QUARTUS_MINOR_VERSION}.${QUARTUS_REVISION_VERSION}.qdz .

RUN chmod a+x QuartusLiteSetup-${QUARTUS_MAJOR_VERSION}std.${QUARTUS_MINOR_VERSION}.${QUARTUS_REVISION_VERSION}-linux.run && \
    ./QuartusLiteSetup-${QUARTUS_MAJOR_VERSION}std.${QUARTUS_MINOR_VERSION}.${QUARTUS_REVISION_VERSION}-linux.run --mode unattended --accept_eula 1 --installdir /opt/intelFPGA && \
    rm -rf /opt/intelFPGA/uninstall/

################################################################################
# Main build image

FROM ubuntu:25.04

ARG DEBIAN_FRONTEND=noninteractive

# Install RISC-V toolchain with confirmed available packages
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        libglib2.0-0 \
        libxext6 \
        libmpc3 \
        libfontconfig1 \
        locales \
        gcc-riscv64-unknown-elf \
        binutils-riscv64-unknown-elf \
        build-essential \
        picolibc-riscv64-unknown-elf \
        libnewlib-dev && \       
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# Set up environment
ENV QUARTUS_PATH=/opt/intelFPGA
ENV QUARTUS_ROOTDIR=${QUARTUS_PATH}/quartus
ENV SOPC_KIT_NIOS2=${QUARTUS_PATH}/nios2eds
ENV PATH=${QUARTUS_ROOTDIR}/bin/:${QUARTUS_ROOTDIR}/linux64/gnu/:${QUARTUS_ROOTDIR}/sopc_builder/bin/:$PATH

# Copy Quartus from the first stage
COPY --from=fpga_install /opt/intelFPGA/ /opt/intelFPGA/

VOLUME /build
WORKDIR /build
