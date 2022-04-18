FROM ubuntu:20.04

USER root
WORKDIR /root

# TeX Live creates a heavy layer, so install it as early as possible to allow caching
COPY install_texlive.sh ./
RUN ./install_texlive.sh

# drawio creates a heavy layer, so install it as early as possible to allow caching
COPY install_drawio.sh ./
RUN ./install_drawio.sh

COPY install_support.sh ./
RUN ./install_support.sh \
  && adduser --disabled-password --gecos "" ci_user \
  && apt-get install sudo \
  && usermod --append --groups sudo ci_user \
  && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
  && mkdir --parents --mode=777 /home/repo

USER ci_user
WORKDIR /home/ci_user

COPY --chown=ci_user \
  license.md \
  readme.md \
  config_user.sh \
  entrypoint.sh \
  entrypoint_usermod.sh \
  ./
# Use /home/repo as repository directory since
# entrypoint script can change ownership of everything in home dir
RUN ./config_user.sh \
  && echo "cd /home/repo" >> ~/.profile

WORKDIR "/home/repo"
ENTRYPOINT ["/home/ci_user/entrypoint.sh"]


# See https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL org.opencontainers.image.authors="Nikita Rudenko"
LABEL org.opencontainers.image.vendor="Nikita Rudenko"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.title="Docker image for LaTeX CI"
LABEL org.opencontainers.image.base.name="ubuntu:20.04"
LABEL org.opencontainers.image.source="https://github.com/rudenkornk/docker_latex"

ARG IMAGE_NAME
LABEL org.opencontainers.image.ref.name="${IMAGE_NAME}"

ARG VERSION
LABEL org.opencontainers.image.version="${VERSION}"

ARG VCS_REF
LABEL org.opencontainers.image.revision="${VCS_REF}"

ARG BUILD_DATE
LABEL org.opencontainers.image.created="${BUILD_DATE}"

