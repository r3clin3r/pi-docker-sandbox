FROM docker/sandbox-templates:shell-docker

SHELL ["/bin/bash", "-c"]

USER root

RUN apt-get update && apt-get install -y \
  # convenience \
  tree bat neovim \
  # required for pnpm installation \
  libatomic1 \
  # required for pi \
  fd-find

USER agent

RUN echo "alias bat='batcat'" >> ~/.bashrc

RUN curl -fsSL https://get.pnpm.io/install.sh | bash -
RUN source ~/.bashrc && pnpm runtime set node lts -g
RUN source ~/.bashrc && pnpm add -g @earendil-works/pi-coding-agent

