#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

if [[ ${GITHUB_ACTIONS:-} != true ]]; then
  exit
fi

TEXLIVEHOME=$(find /home/ci_user -type d -name .texlive*)

echo "TEXMFVAR=$TEXLIVEHOME/texmf-var" >> $GITHUB_ENV
echo "TEXMFCONFIG=$TEXLIVEHOME/texmf-config" >> $GITHUB_ENV
echo "TEXMFHOME=/home/ci_user/texmf" >> $GITHUB_ENV

