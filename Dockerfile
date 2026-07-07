# syntax=docker/dockerfile:1.7

FROM cloudron/base:5.0.0@sha256:04fd70dbd8ad6149c19de39e35718e024417c3e01dc9c6637eaf4a41ec4e596c

RUN mkdir -p /app/code /app/data
WORKDIR /app/code

COPY upstream/package.json ./
RUN npm install

COPY upstream/ ./
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

# Remove source code and build tools, keep runtime deps
RUN rm -rf upstream src docs tests cli .git \
    eslint.config.mjs jsconfig.json postcss.config.mjs next.config.mjs \
    docker-compose.yml Dockerfile captain-definition CLAUDE.md DOCKER.md LICENSE \
    gitbook i18n

# Move standalone output to code root where custom-server.js expects it
RUN cp -r .next/standalone/* . && rm -rf .next

ENV NODE_ENV=production
ENV PORT=20128
ENV HOSTNAME=0.0.0.0
ENV DATA_DIR=/app/data

COPY start.sh ./
COPY CloudronManifest.json ./
RUN chmod +x start.sh

EXPOSE 20128

CMD ["/app/code/start.sh"]
