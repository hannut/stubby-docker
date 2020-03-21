FROM debian:stable-slim
LABEL maintainer="Hannu Teulahti"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
 && apt-get -y full-upgrade \
 && apt-get install -y --no-install-recommends \
	unbound \
    ldnsutils \
    iputils-ping \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && true

COPY a-records.conf /opt/unbound/etc/unbound/
COPY unbound.sh /

RUN chmod +x /unbound.sh

EXPOSE 53/tcp 53/udp

HEALTHCHECK --interval=5s --timeout=3s --start-period=5s CMD drill @127.0.0.1 cloudflare.com || exit 1

CMD ["/unbound.sh"]

