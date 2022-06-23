#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ca-certificates \
  libasound2 \
  wget \
  xvfb \

wget https://github.com/jgraph/drawio-desktop/releases/download/v17.4.2/drawio-amd64-17.4.2.deb
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ./drawio*.deb

rm ./drawio*.deb
rm /usr/bin/drawio

echo '#!/usr/bin/env bash' >> /usr/bin/drawio
echo 'PASSED_COMMAND=$@' >> /usr/bin/drawio
echo 'xvfb-run /opt/drawio/drawio $PASSED_COMMAND --no-sandbox' >> /usr/bin/drawio
chmod 755 /usr/bin/drawio

