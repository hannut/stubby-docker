FROM debian:stable-slim
LABEL maintainer="Hannu Teulahti"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
 && apt-get -y full-upgrade \
 && apt-get install -y --no-install-recommends \
	stubby \
	ca-certificates \
    ldnsutils \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && adduser --system --group stubby \
 && true

EXPOSE 8053/tcp 8053/udp

COPY stubby.yml /etc/stubby/stubby.yml

USER stubby:stubby

HEALTHCHECK --interval=5s --timeout=3s --start-period=5s CMD drill @127.0.0.1 -p 8053 google.com || exit 1

CMD ["/usr/bin/stubby"]

