#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

apt-get update
DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install --yes --no-install-recommends \
  texlive-full
