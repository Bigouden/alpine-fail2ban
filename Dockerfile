# kics-scan disable=f2f903fb-b977-461e-98d7-b3e2185c6118,9513a694-aa0d-41d8-be61-3271e056f36b,d3499f6d-1651-41bb-a9a7-de925fea487b,ae9c56a6-3ed1-4ac0-9b54-31267f51151d,4b410d24-1cbe-4430-a632-62c9a931cf1c,fd54f200-402c-4333-a5a4-36ef6709af2f

ARG ALPINE_VERSION="3.20"

FROM alpine:${ALPINE_VERSION} AS builder
COPY --link apk_packages /tmp/
# checkov:skip=CKV_DOCKER_4
# hadolint ignore=DL3018
RUN --mount=type=cache,id=builder_apk_cache,target=/var/cache/apk \
    apk add gettext-envsubst

FROM alpine:${ALPINE_VERSION}
LABEL maintainer="Thomas GUIRRIEC <thomas@guirriec.frr>"
ENV FAIL2BAN_SOCAT_PORT="12345"
ENV FAIL2BAN_SOCKET_FILE="/run/fail2ban/fail2ban.sock"
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
# hadolint ignore=DL3013,DL3018,DL3042,SC2006
RUN --mount=type=bind,from=builder,source=/usr/bin/envsubst,target=/usr/bin/envsubst \
    --mount=type=bind,from=builder,source=/usr/lib/libintl.so.8,target=/usr/lib/libintl.so.8 \
    --mount=type=bind,readwrite,from=builder,source=/tmp,target=/tmp \
    --mount=type=cache,id=apk_cache,target=/var/cache/apk \
    apk --update add `envsubst < /tmp/apk_packages` \
    && mkdir /run/openrc \
    && touch /run/openrc/softlevel \
    && rc-update add rsyslog default \
    && rc-update add sshd \
    && rc-update add fail2ban
COPY --link --chmod=755 entrypoint.sh /
EXPOSE ${FAIL2BAN_SOCAT_PORT}/tcp
HEALTHCHECK CMD nc -vz localhost "${FAIL2BAN_SOCAT_PORT}" || exit 1 # nosemgrep
ENTRYPOINT ["/entrypoint.sh"]
