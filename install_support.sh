#!/usr/bin/env bash

set -x

echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  file \
  gcc \
  libc6-dev \
  make \
  msttcorefonts \
  python3-pygments \
  poppler-utils \
  ttf-mscorefonts-installer \

(echo y)|cpan
cpan install YAML::Tiny
cpan install File::HomeDir

