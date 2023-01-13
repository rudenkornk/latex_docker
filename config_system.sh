#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  bash-completion \
  file \
  gcc `# for latexindent` \
  libc6-dev `# for latexindent` \
  make \
  msttcorefonts \
  poppler-utils `# for pdfinfo tests` \
  python3-pip \
  python3-pygments `# for minted latex package` \
  python3-venv \
  sudo \
  ttf-mscorefonts-installer \
  vim \

# Perl packages for latexindent
(echo y)|cpan
cpan install YAML::Tiny
cpan install File::HomeDir
