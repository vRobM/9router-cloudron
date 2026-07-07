# syntax=docker/dockerfile:1.7

# ── Build stage ──────────────────────────────────────────────────────────────
FROM node:22-alpine AS builder

RUN apk --no-cache upgrade && apk --no-cache add python3 make g++ linux-headers

WORKDIR /app

COPY upstream/package.json ./
RUN npm install

COPY upstream/ ./
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

# ── Final stage: Cloudron base ──────────────────────────────────────────────
FROM cloudron/base:5.0.0@sha256:04fd70dbd8ad6149c19de39e35718e024417c3e01dc9c6637eaf4a41ec4e596c

RUN mkdir -p /app/code /app/data
WORKDIR /app/code

ENV NODE_ENV=production
ENV PORT=20128
ENV HOSTNAME=0.0.0.0
ENV NEXT_TELEMETRY_DISABLED=1
ENV DATA_DIR=/app/data

# Copy built artifacts from builder
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/custom-server.js ./custom-server.js
COPY --from=builder /app/open-sse ./open-sse
COPY --from=builder /app/src/mitm ./src/mitm

# Standalone node_modules may omit deps required by the MITM child process
COPY --from=builder /app/node_modules/node-forge ./node_modules/node-forge
COPY --from=builder /app/node_modules/next ./node_modules/next

# Copy startup script and manifest
COPY start.sh ./start.sh
COPY CloudronManifest.json ./CloudronManifest.json
RUN chmod +x start.sh

EXPOSE 20128

CMD ["/app/code/start.sh"]
