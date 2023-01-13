#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
  ca-certificates \
  libasound2 \
  libgbm1 \
  wget \
  xvfb \

wget https://github.com/jgraph/drawio-desktop/releases/download/v20.7.4/drawio-amd64-20.7.4.deb
DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends ./drawio*.deb

rm ./drawio*.deb
rm /usr/bin/drawio

cp /etc/configs/drawio.sh /usr/bin/drawio

chmod 755 /usr/bin/drawio
