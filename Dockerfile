# ─── Stage 1: Builder ─────────────────────────────────────────────────────────
FROM oven/bun:1 AS builder

WORKDIR /app

# Copy package files
COPY package.json bun.lock* ./

# Install dependencies
RUN bun install --frozen-lockfile

# Copy prisma schema dan generate client
COPY prisma ./prisma
RUN bunx prisma generate

# Copy source code
COPY . .

# ─── Stage 2: Production ──────────────────────────────────────────────────────
FROM oven/bun:1-debian AS production

WORKDIR /app

# Install Chromium dan dependencies untuk WhatsApp Web.js (Puppeteer)
RUN apt-get update && apt-get install -y \
    chromium \
    fonts-liberation \
    fonts-noto-color-emoji \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libxshmfence1 \
    xdg-utils \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Variabel environment Puppeteer agar pakai system Chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Copy dari stage builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/src ./src
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/tsconfig.json ./tsconfig.json

# Buat direktori untuk WhatsApp session dan SQLite
RUN mkdir -p /app/.wwebjs_auth /app/data

# Port yang digunakan aplikasi
EXPOSE 3000

# Jalankan aplikasi
CMD ["bun", "run", "src/server.ts"]
