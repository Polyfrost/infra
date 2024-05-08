FROM alpine:3 as builder

ARG XCADDY_VERSION
ARG CADDY_VERSION

RUN apk add --no-cache go git && mkdir /tmp/caddy-build

ADD https://github.com/caddyserver/xcaddy/releases/download/v${XCADDY_VERSION}/xcaddy_${XCADDY_VERSION}_linux_amd64.tar.gz /tmp/caddy-build/xcaddy.tgz

RUN cd /tmp/caddy-build/ && tar -zxvf xcaddy.tgz xcaddy && ./xcaddy build v${CADDY_VERSION} --with github.com/caddy-dns/cloudflare --with github.com/WeidiDeng/caddy-cloudflare-ip --output /usr/local/bin/caddy

FROM alpine:3

WORKDIR /srv/caddy

COPY --from=builder /usr/local/bin/caddy /usr/local/bin/caddy

CMD caddy run --config /srv/caddy/Caddyfile --watch