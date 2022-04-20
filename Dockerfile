FROM ubuntu:20.04

# First, ask system administrator to install necessary packages
USER root
WORKDIR /root

# TeX Live creates a heavy layer, so install it as early as possible to allow caching
COPY install_texlive.sh ./
RUN ./install_texlive.sh

# drawio creates a heavy layer, so install it as early as possible to allow caching
COPY install_drawio.sh ./
RUN ./install_drawio.sh

COPY install_support.sh ./
RUN ./install_support.sh

# Create new user for CI and temprorarily give them admin privileges
# The latter is needed for changing user id to match id of user in the host system
# Also, use /home/repo as mounting point, instead for home dir, since
# entrypoint script can change ownership of everything in home dir
RUN : \
  && adduser --disabled-password --gecos "" ci_user \
  && apt-get install sudo \
  && usermod --append --groups sudo ci_user \
  && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
  && mkdir --parents --mode=777 /home/repo \
  && echo "cd /home/repo" >> /home/ci_user/.profile

# Second, install fonts and setup environment
USER ci_user
WORKDIR /home/ci_user

COPY --chown=ci_user \
  license.md \
  readme.md \
  config_user.sh \
  ./
RUN ./config_user.sh

# Entrypoint allows to change ci_user's id and removes admin privileges from them
COPY --chown=ci_user \
  entrypoint.sh \
  entrypoint_usermod.sh \
  ./
WORKDIR "/home/repo"
ENTRYPOINT ["/home/ci_user/entrypoint.sh"]


# See https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL org.opencontainers.image.authors="Nikita Rudenko"
LABEL org.opencontainers.image.vendor="Nikita Rudenko"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.title="Docker image for LaTeX CI"
LABEL org.opencontainers.image.base.name="ubuntu:20.04"

ARG IMAGE_NAME
LABEL org.opencontainers.image.ref.name="${IMAGE_NAME}"
LABEL org.opencontainers.image.url="https://hub.docker.com/repository/docker/${IMAGE_NAME}"
LABEL org.opencontainers.image.source="https://github.com/${IMAGE_NAME}"

ARG VERSION
LABEL org.opencontainers.image.version="${VERSION}"

ARG VCS_REF
LABEL org.opencontainers.image.revision="${VCS_REF}"

ARG BUILD_DATE
LABEL org.opencontainers.image.created="${BUILD_DATE}"

