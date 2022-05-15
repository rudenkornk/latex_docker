#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  file \
  gcc `# for latexindent` \
  libc6-dev `# for latexindent` \
  make \
  msttcorefonts \
  poppler-utils `# for pdfinfo tests` \
  python3-pygments `# for minted latex package` \
  ttf-mscorefonts-installer \

# Perl packages for latexindent
(echo y)|cpan
cpan install YAML::Tiny
cpan install File::HomeDir

