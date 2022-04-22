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

# Create new user for local CI
# This also simulates typical system, when LaTeX document creator is a normal user
RUN adduser --disabled-password --gecos "" ci_user

# Second, install fonts and setup environment
USER ci_user
WORKDIR /home/ci_user

COPY --chown=ci_user \
  license.md \
  readme.md \
  config_user.sh \
  ./
RUN ./config_user.sh

# At this point the image simulated normal installation process on a typical system
# Further steps on this typical system would be downloading some LaTeX repo and compiling it
# On the other hand the image should support two use cases:
#  1. Using it for local testing
#  2. Using it for CI like GitHub Actions
# The first one should use a normal user with user id matching user id of the host system
# We cannot user root for local testing since it will create its output inaccessible by the host user (unless they use "sudo", but it is a brute solution)
# In contrary, the second one requires that last USER command must be root and we also cannot rely on entrypoint script, and even on home directory (that is because of the way GitHub Actions use provided image)
# See also https://docs.github.com/en/actions/creating-actions/dockerfile-support-for-github-actions
#
# In order to satisfy both requirements we use the following strategy:
# For the first use case we promise that we run local testing only with "--user ci_user" option and default entrypoint script, which changes ci_user's id
# For the second use case we leave root as the default user for image, and on client side run config script

USER root

# Temprorarily give ci_user admin privileges
# The latter is needed when "docker run" is used with "--user ci_user" option.
# Without sudo rights, ci_user will not be able to run entrypoint script and change its id
# Also, use /home/repo as mounting point, instead of home dir, since
# entrypoint script can change ownership of everything in home dir
RUN : \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    sudo \
  && usermod --append --groups sudo ci_user \
  && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
  && mkdir --parents --mode=777 /home/repo \
  && echo "cd /home/repo" >> /home/ci_user/.profile

# Entrypoint allows to change ci_user's id and removes admin privileges from them
# Copy it to ci_user's directory to allow access both to root and ci_user
# Also copy config_github_actions.sh, which acts like entrypoint on client's side in GitHub Actions
COPY --chown=ci_user \
  config_github_actions.sh \
  entrypoint.sh \
  entrypoint_usermod.sh \
  /home/ci_user/

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

