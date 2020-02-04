FROM node:12.14.1-alpine as builder

ARG BOARDR_API_URL

WORKDIR /usr/src/app

RUN apk add --no-cache curl && \
    curl -L -o /tmp/elm.gz https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz && \
    gunzip /tmp/elm.gz && \
    mv /tmp/elm /usr/local/bin/ && \
    chmod +x /usr/local/bin/elm && \
    elm --version

COPY . /usr/src/app

RUN npm ci && npm run build

FROM pierrezemb/gostatic

COPY --from=builder /usr/src/app/dist/ /srv/http/

CMD [ "-fallback", "/index.html" ]
