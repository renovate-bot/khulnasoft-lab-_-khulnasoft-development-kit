FROM jdkato/vale AS vale-source

FROM ubuntu:24.04

ARG git_checkout_branch
ENV GIT_CHECKOUT_BRANCH $git_checkout_branch

ARG git_remote_origin_url
ENV GIT_REMOTE_ORIGIN_URL $git_remote_origin_url

ARG workspace_user=khulnasoft-workspaces
ENV WORKSPACE_USER ${workspace_user}

ENV HOME=/home/${WORKSPACE_USER}

ENV WORKSPACE_DIR_NAME ${HOME}/workspace

ENV ASDF_DIR=$WORKSPACE_DIR_NAME/.asdf
ENV ASDF_DATA_DIR=$WORKSPACE_DIR_NAME/.asdf

# --- Install vale (scripts/lint-doc.sh dependency)
COPY --from=vale-source /bin/vale /usr/bin/vale

COPY configure-image-base.sh /tmp
RUN bash /tmp/configure-image-base.sh

WORKDIR ${HOME}

COPY install-additional-tools.sh /tmp
RUN bash /tmp/install-additional-tools.sh

WORKDIR $WORKSPACE_DIR_NAME

USER ${WORKSPACE_USER}

COPY --chown=${WORKSPACE_USER} bootstrap-remote-development-image.sh /tmp
RUN bash /tmp/bootstrap-remote-development-image.sh

COPY entrypoint.sh /tmp
ENTRYPOINT ["/tmp/entrypoint.sh"]
