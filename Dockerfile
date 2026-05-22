FROM debian:bookworm AS base

FROM base AS builder

RUN cat <<EOF > /etc/apt/sources.list.d/source.sources
Types: deb-src
# http://snapshot.debian.org/archive/debian/20250428T000000Z
URIs: http://deb.debian.org/debian
Suites: bookworm bookworm-updates
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

RUN apt update \
&& apt build-dep -y mesa \
&& apt install -y git cmake

RUN echo "deb http://deb.debian.org/debian bookworm-backports main" > /etc/apt/sources.list.d/backports.list
RUN apt update && apt install -y python3-pycparser meson/bookworm-backports

RUN cd /tmp \
&& git clone --depth 1 https://gitlab.freedesktop.org/mesa/mesa.git -b mesa-26.1.1 \
&& cd mesa \
&& meson setup build -Dgallium-drivers=ethosu,etnaviv,rocket -Dvulkan-drivers= -Dteflon=true \
&& meson compile -C build \
&& strip --strip-unneeded /tmp/mesa/build/src/gallium/targets/teflon/libteflon.so

FROM base AS image
COPY --from=builder /tmp/mesa/build/src/gallium/targets/teflon/libteflon.so /tmp/
