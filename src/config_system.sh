#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

DISTRO=$(lsb_release --codename --short)
ARCH=$(dpkg --print-architecture)
PUBKEY=/etc/apt/trusted.gpg.d/nodejs.asc
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key > $PUBKEY
echo "deb [arch=$ARCH signed-by=$PUBKEY] https://deb.nodesource.com/node_19.x $DISTRO main" > /etc/apt/sources.list.d/nodejs.list


echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  bash-completion \
  file \
  gcc `# for latexindent` \
  libc6-dev `# for latexindent` \
  make \
  msttcorefonts \
  nodejs `# for prettier formatter` \
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
