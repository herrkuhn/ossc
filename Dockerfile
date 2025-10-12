################################################################################
# quartus image

ARG UBUNTU_VERSION=25.10

FROM ubuntu:${UBUNTU_VERSION} as fpga_install

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

FROM ubuntu:${UBUNTU_VERSION}

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
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen en_US.UTF-8

# Set up environment
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    QUARTUS_PATH=/opt/intelFPGA \
    QUARTUS_ROOTDIR=/opt/intelFPGA/quartus \
    SOPC_KIT_NIOS2=/opt/intelFPGA/nios2eds

ENV PATH=${QUARTUS_ROOTDIR}/bin/:${QUARTUS_ROOTDIR}/linux64/gnu/:${QUARTUS_ROOTDIR}/sopc_builder/bin/:$PATH

# Copy Quartus from the first stage
COPY --from=fpga_install /opt/intelFPGA/ /opt/intelFPGA/

VOLUME /build
WORKDIR /build
