# syntax=docker/dockerfile:1

# Start from Docker's official hardened pi image. It carries pi, the `sbx`
# launch contract, and the toolset the workload descriptor expects.
FROM docker.io/sbx/pi:latest

USER root

# The official image embeds its own kit descriptor at
# /usr/share/sandbox/kit/pi, which declares Anthropic network access and an
# Anthropic credential. This workload configures fireworks.ai instead, so drop
# the bundled descriptor rather than inherit a provider we do not use.
RUN rm -rf /usr/share/sandbox/kit/pi

# The base image labels itself as the `pi` kit. Point the label at this kit so
# nothing resolves the descriptor we just removed.
LABEL com.docker.dash.kit="pi-fireworks"

USER agent
