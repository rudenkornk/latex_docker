#!/usr/bin/env bash

set -x

echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  make \
  file \
  msttcorefonts \
  python3-pygments \
  ttf-mscorefonts-installer \

