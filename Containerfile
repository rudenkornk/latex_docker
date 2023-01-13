FROM docker.io/library/ubuntu:22.04

WORKDIR /etc/configs

# TeX Live creates a heavy layer, so install it as early as possible to allow caching
COPY install_texlive.sh ./
RUN ./install_texlive.sh

# drawio creates a heavy layer, so install it as early as possible to allow caching
COPY \
  install_drawio.sh \
  drawio.sh \
  ./
RUN ./install_drawio.sh

COPY config_system.sh ./
RUN ./config_system.sh

COPY license.md ./

WORKDIR /root

# See https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL org.opencontainers.image.authors="Nikita Rudenko"
LABEL org.opencontainers.image.base.name="ubuntu:22.04"
LABEL org.opencontainers.image.description="Container image for LaTeX builds."
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.vendor="Nikita Rudenko"
