# Builder image to compile the application
# ========================================
FROM elixir:1.9.4-alpine as builder

ARG ARCH=amd64

WORKDIR /usr/src/app

ENV MIX_ENV=prod

RUN mix local.hex --force && \
    mix local.rebar --force

COPY mix.exs mix.lock /usr/src/app/
COPY apps/boardr/mix.exs /usr/src/app/apps/boardr/
COPY apps/boardr_api/mix.exs /usr/src/app/apps/boardr_api/

RUN mix deps.get --only $MIX_ENV

COPY config/config.exs config/prod.exs /usr/src/app/config/

RUN mix deps.compile

COPY . /usr/src/app/

RUN mix release boardr_api

# Production image to run the application
# =======================================
FROM alpine:3.10

LABEL maintainer="docker@alphahydrae.com"

WORKDIR /usr/src/app

RUN apk add --no-cache ncurses && \
    addgroup -g 1000 -S boardr && \
    adduser -D -G boardr -s /bin/sh -S -u 1000 boardr && \
    chown boardr:boardr /usr/src/app

COPY --chown=boardr:boardr --from=builder /usr/src/app/_build/prod/rel/boardr_api/ /usr/src/app/

ENV BOARDR_PORT=4000

USER boardr:boardr

CMD [ "/usr/src/app/bin/boardr_api", "start" ]

HEALTHCHECK --interval=10s --timeout=30s --start-period=5s --retries=3 \
            CMD wget -qO- http://localhost:${BOARDR_PORT}/api

EXPOSE 4000 4369 9000