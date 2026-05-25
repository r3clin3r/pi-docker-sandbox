#!/usr/bin/env bash

set -e

docker image save pi-docker-sandbox:latest -o pi-docker-sandbox.tar
sbx template load pi-docker-sandbox.tar
