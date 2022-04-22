#!/usr/bin/env bash

set -x

if [[ $GITHUB_ACTIONS != true ]]; then
  exit
fi

source /home/ci_user/.profile
TEXLIVEHOME=$(find /home/ci_user -type d -name .texlive*)

echo "TEXMFVAR=$TEXLIVEHOME/texmf-var" >> $GITHUB_ENV
echo "TEXMFCONFIG=$TEXLIVEHOME/texmf-config" >> $GITHUB_ENV
echo "TEXMFHOME=/home/ci_user/texmf" >> $GITHUB_ENV
echo "DRAWIO_CMD=$DRAWIO_CMD" >> $GITHUB_ENV

