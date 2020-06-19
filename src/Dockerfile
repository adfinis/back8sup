FROM alpine:latest

LABEL org.opencontainers.image.authors="Antonio Tauro <toni.tauro@adfinis.com>"

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
