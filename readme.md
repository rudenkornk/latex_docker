# Docker image for LaTeX CI

Docker image for LaTeX CI.
Includes TeXLive full installation as well as draw.io package

## Build
```shell
make docker_image
```

## Run
```shell
CI_BIND_MOUNT=$(pwd) make docker_container

docker attach docker_latex_container
# OR
docker exec -it docker_latex_container bash -c "source ~/.profile && bash"
```

