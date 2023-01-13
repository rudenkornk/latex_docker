# Container image for LaTeX builds

Container image for reproducible LaTeX builds targeting local and CI usage.
Includes TeXLive full installation as well as draw.io package

[![GitHub Actions Status](https://github.com/rudenkornk/latex_image/actions/workflows/workflow.yml/badge.svg)](https://github.com/rudenkornk/latex_image/actions)


## Using the image
Set up your build system to run inside container.

```bash
# Bootstrap
podman run --interactive --tty --detach \
  --cap-add=SYS_ADMIN `# for drawio` \
  --env "TERM=xterm-256color" `# colored terminal` \
  --mount type=bind,source="$(pwd)",target="$(pwd)" `# mount your repo` \
  --name latex \
  --userns keep-id `# keeps your non-root username` \
  --workdir "$HOME" `# podman sets homedir to the workdir for some readon` \
  ghcr.io/rudenkornk/latex_image:latest # DO NOT ACTUALLY USE 'latest', ALWAYS PIN EXACT VERSION!
podman exec --user root latex bash -c "chown $(id --user):$(id --group) $HOME"

# Execute single command
podman exec --workdir "$(pwd)" latex bash -c 'your_command'

# Attach to container
podman exec --workdir "$(pwd)" --interactive --tty latex bash
```

## Build
**Requirements:** `podman >= 3.4.4`, `GNU Make >= 4.3`  
```bash
make
```

## Test
**Requirements:** Also `pdfinfo >= 22`, `ifne`, `curl >= 7.81.0`  
```bash
make check
```

## Clean
```bash
make clean
```
