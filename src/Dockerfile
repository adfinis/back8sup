FROM alpine:latest

LABEL org.opencontainers.image.title="back8sup" \
      org.opencontainers.image.description="A simple way to backup your kubernetes resources" \
      org.opencontainers.image.authors="Adfinis AG <https://adfinis.com>" \
      org.opencontainers.image.vendor="Adfinis" \
      org.opencontainers.image.url="https://github.com/adfinis-sygroup/back8sup" \
      org.opencontainers.image.licenses="AGPL-3.0-or-lateræ


ADD back8sup.sh /

ENV KUBECTL_VERSION=v1.17.0

RUN chmod +x /back8sup.sh \
  && apk add --no-cache bash jq curl py3-pip \
  && curl -L -o/usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
  && chmod +x /usr/local/bin/kubectl \
  && pip3 --no-cache-dir install yamllint yq \
  && mkdir -p /workdir \
  && chgrp 0 -R /workdir \
  && chmod g=u -R /workdir

WORKDIR /workdir
ENV HOME /workdir
USER 65534

CMD ["/back8sup.sh"]
