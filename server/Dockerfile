# Builder image to compile the application
# ========================================
FROM elixir:1.9.4-alpine as builder

WORKDIR /usr/src/app

ENV MIX_ENV=prod

RUN mix local.hex --force && \
    mix local.rebar --force

COPY mix.exs mix.lock /usr/src/app/

RUN mix deps.get && \
    mix deps.compile

COPY . /usr/src/app/

RUN mix release boardr

# Production image to run the application
# =======================================
FROM alpine:3.10

LABEL maintainer="docker@alphahydrae.com"

WORKDIR /usr/src/app

RUN apk add --no-cache ncurses && \
    addgroup -g 1000 -S boardr && \
    adduser -D -G boardr -H -s /bin/false -S -u 1000 boardr && \
    chown boardr:boardr /usr/src/app

COPY --chown=boardr:boardr --from=builder /usr/src/app/_build/prod/rel/boardr/ /usr/src/app/

USER boardr:boardr

ENV BOARDR_PORT=4000

CMD [ "/usr/src/app/bin/boardr", "start" ]

EXPOSE 4000