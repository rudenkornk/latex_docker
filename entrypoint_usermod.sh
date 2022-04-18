#!/usr/bin/env bash

if [[ ! -z "$CI_UID" ]]; then
    if [[ $CI_UID -lt 1000 ]]; then
        echo "ERROR: CI user id must be >= 1000!"
        exit 1
    fi
    # No need to change ownership in home dir since usermod does it itself
    usermod --uid $CI_UID ci_user
fi

if [[ ! -z "$CI_GID" ]]; then
    if [[ $CI_GID -lt 1000 ]]; then
        echo "ERROR: CI group id must be >= 1000!"
        exit 1
    fi
    groupmod --gid $CI_GID ci_user
    chgrp --recursive $CI_GID /home/ci_user
fi

# Drop privileges and execute next container command, or 'bash' if not specified.
sudo deluser --quiet ci_user sudo
if [[ $# -gt 0 ]]; then
    exec sudo --login --user=$USER -- "$@"
else
    exec sudo --login --user=$USER -- bash
fi

