FROM ubuntu:24.04
LABEL authors.maintainer="KDK contributors: https://github.com/khulnasoft-com/khulnasoft-development-kit"

## The CI script that build this file can be found under: support/docker

ARG TOOL_VERSION_MANAGER

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV TOOL_VERSION_MANAGER=${TOOL_VERSION_MANAGER}

RUN apt-get update && \
    apt-get install -y \
      curl \
      libssl-dev \
      locales \
      locales-all \
      lsof \
      pkg-config \
      software-properties-common \
      sudo && \
    add-apt-repository ppa:git-core/ppa -y

RUN useradd --user-group --create-home --groups sudo kdk && \
    echo "kdk ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/kdk_no_password

WORKDIR /home/kdk/tmp
RUN chown -R kdk:kdk /home/kdk

USER kdk
COPY --chown=kdk . .

ENV PATH="/home/kdk/.local/bin:/home/kdk/.local/share/mise/bin:/home/kdk/.local/share/mise/shims:/home/kdk/.asdf/shims:/home/kdk/.asdf/bin:${PATH}"

# Perform bootstrap
# Verify that tools are available
# Remove unneeded packages
# Remove caches & copied files
# Remove all files from "$HOME/kdk/gitaly/_build" except the compiled binaries in "bin"
RUN bash ./support/bootstrap && \
    bash -eclx "${TOOL_VERSION_MANAGER} version; yarn --version; node --version; ruby --version" && \
    sudo apt-get purge software-properties-common -y && \
    sudo apt-get clean -y && \
    sudo apt-get autoremove -y && \
    sudo rm -rf \
      "$HOME/.asdf/tmp/"* \
      "$HOME/.cache/" \
      "$HOME/tmp" \
      /tmp/* \
      /var/cache/apt/* \
      /var/lib/apt/lists/* \
      $(ls -d "$HOME/kdk/gitaly/_build/"* | grep -v /bin)

WORKDIR /home/kdk
