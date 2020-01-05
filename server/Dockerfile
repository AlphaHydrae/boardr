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

ADD https://github.com/just-containers/s6-overlay/releases/download/v1.21.8.0/s6-overlay-amd64.tar.gz /tmp/
RUN mkdir /s6 && \
    tar xzf /tmp/s6-overlay-amd64.tar.gz -C /s6

# Production image to run the application
# =======================================
FROM alpine:3.10

LABEL maintainer="docker@alphahydrae.com"

WORKDIR /usr/src/app

COPY --from=builder /s6/ /
COPY ./docker/ /

RUN apk add --no-cache ncurses openssh shadow sudo && \
    echo 'Defaults env_keep += "BOARDR_BASE_URL BOARDR_DATABASE_URL BOARDR_JWT_PRIVATE_KEY BOARDR_PORT"' >> /etc/sudoers && \
    visudo -c && \
    mkdir /root/.ssh && \
    chmod 700 /root/.ssh && \
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config && \
    sed -i "s/AllowTcpForwarding no/AllowTcpForwarding yes/" /etc/ssh/sshd_config && \
    ssh-keygen -A && \
    chmod 755 /etc/services.d/*/* && \
    addgroup -g 1000 -S boardr && \
    adduser -D -G boardr -s /bin/sh -S -u 1000 boardr && \
    chown boardr:boardr /usr/src/app && \
    (umask 077 && mkdir /home/boardr/.ssh) && \
    (umask 066 && touch /home/boardr/.ssh/authorized_keys) && \
    chown -R boardr:boardr /home/boardr/.ssh && \
    usermod -p '*' boardr

COPY --chown=boardr:boardr --from=builder /usr/src/app/_build/prod/rel/boardr/ /usr/src/app/

ENV BOARDR_PORT=4000

CMD [ "/init" ]

EXPOSE 22 4000 4369 9000