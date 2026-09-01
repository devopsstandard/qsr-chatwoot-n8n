# ==========================================
# Stage 1: Build Dependencies & Asset Compilation
# ==========================================
FROM ruby:3.3.0-slim-bookworm AS builder

# Install build essential packages & NodeJS
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential \
    gnupg2 \
    curl \
    git \
    libpq-dev \
    libvips-dev \
    pkg-config \
 && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && corepack enable \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' \
 && bundle install --jobs 4 --retry 3

# Copy package.json and install JS dependencies
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy application source code
COPY . .

# Precompile Rails assets
ENV RAILS_ENV=production
ENV SECRET_KEY_BASE=dummy_key_for_precompile
RUN bundle exec rails assets:precompile

# ==========================================
# Stage 2: Minimal Non-Root Production Runtime
# ==========================================
FROM ruby:3.3.0-slim-bookworm AS runner

# Install runtime dependencies
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    libpq5 \
    libvips42 \
    curl \
    postgresql-client \
    tzdata \
 && rm -rf /var/lib/apt/lists/*

# Create non-root system user and group (UID/GID 10001)
RUN groupadd -g 10001 chatwoot \
 && useradd -u 10001 -g chatwoot -m -s /bin/bash chatwoot

WORKDIR /app

# Copy installed gems and precompiled assets from builder
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder --chown=chatwoot:chatwoot /app /app

# Create required runtime directories and fix permissions
RUN mkdir -p tmp/pids tmp/sockets storage log \
 && chown -R chatwoot:chatwoot /app

USER 10001:10001

EXPOSE 3000

ENTRYPOINT ["/app/docker/chatwoot/entrypoint.sh"]
CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0", "-p", "3000"]
