FROM rudenkornk/docker_ci:1.0.0

# First, ask system administrator to install necessary packages
USER root
WORKDIR /root

# TeX Live creates a heavy layer, so install it as early as possible to allow caching
COPY install_texlive.sh ./
RUN ./install_texlive.sh

# drawio creates a heavy layer, so install it as early as possible to allow caching
COPY install_drawio.sh ./
RUN ./install_drawio.sh

COPY config_system.sh ./
RUN ./config_system.sh

# Second, install fonts and setup environment
USER ci_user
WORKDIR /home/ci_user

COPY --chown=ci_user config_user.sh ./
RUN ./config_user.sh

COPY --chown=ci_user \
  license.md \
  readme.md \
  ./

WORKDIR /home/repo

# GitHub Actions require that root is the default user
# Also copy config_github_actions.sh, which acts like entrypoint on client's side in GitHub Actions
USER root
COPY --chown=ci_user \
  config_github_actions.sh \
  /home/ci_user/

# See https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL org.opencontainers.image.authors="Nikita Rudenko"
LABEL org.opencontainers.image.vendor="Nikita Rudenko"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.title="Docker image for LaTeX CI"
LABEL org.opencontainers.image.base.name="rudenkornk/docker_ci:1.0.0"

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

