FROM alpine as build

ARG QEMU_GIT_TAG=xilinx-v2019.1

LABEL maintainer "Masaki Muranaka <monaka@pizzafactory.jp>"

RUN apk add --no-cache \
      git \
      build-base \
      python \
      glib-dev \
      libgcrypt-dev \
      zlib-dev \
      autoconf \
      automake \
      libtool \
      bison \
      flex \
      pixman-dev \
      dtc

WORKDIR /projects
RUN git clone -b $QEMU_GIT_TAG --recursive https://github.com/Xilinx/qemu.git
WORKDIR /projects/qemu
COPY 0001-undef-PAGE_SIZE.patch 0001-undef-PAGE_SIZE.patch
RUN patch -p1 < 0001-undef-PAGE_SIZE.patch
RUN ./configure --target-list="aarch64-softmmu,microblazeel-softmmu" --enable-fdt --disable-kvm --disable-xen --disable-werror --disable-smartcard
RUN make
RUN make install

WORKDIR /projects
RUN git clone --recursive git://github.com/Xilinx/qemu-devicetrees.git
WORKDIR /projects/qemu-devicetrees
RUN make OUTDIR=/var/dts


FROM pizzafactory0contorno/piatto:alpine

USER root

COPY --from=build \
    /usr/local/bin \
    /usr/local/bin

COPY --from=build \
    /usr/local/share/qemu \
    /usr/local/share/qemu

COPY --from=build \
    /var/dts \
    /var/dts

RUN apk add --no-cache pixman glib libgcc glib libgcrypt zlib libbz2 libstdc++

EXPOSE 1234
USER user
