#!/usr/bin/env bash

# Credit: https://github.com/rlespinasse/docker-drawio-desktop-headless

TIMEOUT=30s

export DRAWIO_DISABLE_UPDATE="true"
export DISPLAY=":0"

timeout $TIMEOUT xvfb-run /opt/drawio/drawio "$@" --no-sandbox 2>&1 |
    grep -v "Failed to connect to socket" |
    grep -v "Could not parse server address" |
    grep -v "Floss manager not present" |
    grep -v "Exiting GPU process" |
    grep -v "called with multiple threads" |
    grep -v "extension not supported" |
    grep -v "Failed to send GpuControl.CreateCommandBuffer"
