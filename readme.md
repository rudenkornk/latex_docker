# Docker image for LaTeX CI

Docker image for LaTeX CI.
Includes TeXLive full installation as well as draw.io package

[![GitHub Actions Status](https://github.com/rudenkornk/docker_latex/actions/workflows/workflow.yml/badge.svg)](https://github.com/rudenkornk/docker_latex/actions)


## Build
```shell
make rudenkornk/docker_latex
```
Also, you can use Docker Hub image as cache source:
```shell
docker pull rudenkornk/docker_latex:latest
DOCKER_CACHE_FROM=rudenkornk/docker_latex:latest make rudenkornk/docker_latex
```


## Test
```shell
make check
```

## Run
```shell
CI_BIND_MOUNT=$(pwd) make docker_latex_container

docker attach docker_latex_container
# OR
docker exec -it docker_latex_container bash -c "source ~/.profile && bash"
```

## Clean
```shell
make clean
# Optionally clean entire docker system and remove ALL containers
./clean_all_docker.sh
```

## Different use cases for this repository
This repository supports three different scenarios

### 1. Use it in your LaTeX CI
For example, in GitHub Actions that might look like:

```yaml
jobs:
  build:
    runs-on: "ubuntu-20.04"
    container:
      image: rudenkornk/docker_latex:0.3.0
    steps:
    - name: Checkout repository
      uses: actions/checkout@v3
    - name: Install prerequisites
      run: /home/ci_user/config_github_actions.sh
    - name: Build
      run: # some build steps
```

Here, `/home/ci_user/config_github_actions.sh` is used to set `DRAWIO_CMD` and some specific texlive environmet variables.
It can be skipped if you do not use draw.io

### 2. Use image for your local testing

```shell
docker run --interactive --tty \
  --user ci_user \
  --env CI_UID="$(id --user)" --env CI_GID="$(id --group)" \
  --mount type=bind,source="$(pwd)",target=/home/repo \
  rudenkornk/docker_latex:latest
```

Instead of `$(pwd)` use path to your LaTeX repo.
It is recommended to mount it into `/home/repo`.
Be careful if mounting inside `ci_user`'s home directory (`/home/ci_user`): entrypoint script will change rights to what is written in `CI_UID` and `CI_GID` vars of everything inside home directory.

### 3. Use scripts from this repository to setup your own system:

```shell
# First, ask system administrator to install necessary packages
sudo ./install_texlive.sh
sudo ./install_drawio.sh
sudo ./install_support.sh

# Second, install fonts and setup environment
./config_user.sh
```

