FROM debian:latest

WORKDIR /gitlab-kdk

COPY additional_packages_*.txt /gitlab-kdk/

# Prepare the 'raw' container image for KDK
RUN ARCH=$(uname -m) \
    && apt-get update \
    && apt-get install -y \
      chromium-driver \
      cmake \
      curl \
      g++ \
      git \
      libssl-dev \
      locales \
      make \
      pkg-config \
      software-properties-common \
      sudo \
      vim \
      $(sed -e 's/#.*//' "additional_packages_${ARCH}.txt") \
    && rm -rf /var/lib/apt/lists/* \
    && rm additional_packages_*.txt \
    && useradd kdk -u 5001 -m -s /bin/bash \
    && chown -Rv kdk:kdk /gitlab-kdk \
    && sed -i "s|# en_US.UTF-8 UTF-8|en_US.UTF-8 UTF-8|" /etc/locale.gen \
    && sed -i "s|# C.UTF-8 UTF-8|C.UTF-8 UTF-8|" /etc/locale.gen \
    && locale-gen C.UTF-8 en_US.UTF-8

COPY --chmod=600 --chown=root:root ./kdk_sudoers /etc/sudoers.d/kdk_sudoers
COPY --chmod=755 --chown=kdk:kdk ./kdk-container-startup.sh /home/kdk/kdk-container-startup.sh

USER kdk

SHELL ["/bin/bash", "-c"]

# Prepare Mise
RUN mkdir -p ~/.config/mise \
    && curl https://mise.run | sh \
    && eval "$(~/.local/bin/mise activate bash)" \
    && echo "# Added to support mise for KDK" >> ~/.bashrc \
    && echo "eval \"\$(~/.local/bin/mise activate bash)\"" >> ~/.bashrc

# Prepare KDK and prereqs (bootstrap)
RUN eval "$(~/.local/bin/mise activate bash)" \
    && git clone https://github.com/khulnasoft-lab/khulnasoft-development-kit.git \
    && cd khulnasoft-development-kit \
    && ln -s /gitlab-kdk/khulnasoft-development-kit ~/khulnasoft-development-kit \
    && echo -e "---\nasdf:\n  opt_out: true\nmise:\n  enabled: true\n" > kdk.yml \
    && make bootstrap \
    # KDK bootstrap runs _more_ apt actions, lets clean out the cache
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/*

# Prepare the container for SSH access
# We do some of these steps down here, because it's _after_ KDK installation
RUN mkdir -p ~/.ssh \
    && cp /gitlab-kdk/khulnasoft-development-kit/support/kdk-in-a-box/kdk.local_rsa.pub ~/.ssh/authorized_keys \
    && chmod 600 ~/.ssh/authorized_keys \
    && sudo mkdir -p /run/sshd \
    && sudo mv /etc/ssh /etc/ssh-bootstrap \
    && sudo mkdir /etc/ssh

WORKDIR /gitlab-kdk/khulnasoft-development-kit

COPY --chmod=755 --chown=kdk:kdk ./install-config-kdk.sh /gitlab-kdk/khulnasoft-development-kit/install-config-kdk.sh

# Install and configure KDK
RUN ./install-config-kdk.sh

VOLUME /etc/ssh

EXPOSE 2022/tcp
EXPOSE 2222/tcp
EXPOSE 3000/tcp
EXPOSE 3005/tcp
EXPOSE 3010/tcp
EXPOSE 3038/tcp
EXPOSE 5100/tcp
EXPOSE 5778/tcp
EXPOSE 9000/tcp

CMD ["/home/kdk/kdk-container-startup.sh"]
