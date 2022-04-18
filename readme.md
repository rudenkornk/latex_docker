# Docker image for LaTeX CI

Docker image for LaTeX CI.
Includes TeXLive full installation as well as draw.io package

## Build
```shell
make docker_image
```

## Test
```shell
make check
```

## Run
```shell
CI_BIND_MOUNT=$(pwd) make docker_container

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

