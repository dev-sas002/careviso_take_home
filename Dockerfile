# syntax=docker/dockerfile:1
#
# Three stages: a shared runtime base, a builder that needs compilers and Node,
# and the image that actually ships — which has neither.
#
#   docker compose up --build        boots Postgres + the app, seeded
#   docker compose run --rm test     runs the spec suite in the builder stage
#
# RUBY_VERSION matches .ruby-version; NODE_VERSION matches the major in .nvmrc.
ARG RUBY_VERSION=3.4.12
ARG NODE_VERSION=24.22.2

# --- base -------------------------------------------------------------------
FROM ruby:${RUBY_VERSION}-slim-bookworm AS base

RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends \
      curl libpq5 postgresql-client tzdata \
 && rm -rf /var/lib/apt/lists/*

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    LANG=C.UTF-8 \
    RAILS_LOG_TO_STDOUT=true

RUN groupadd --system --gid 1000 rails \
 && useradd --system --uid 1000 --gid rails --create-home rails

WORKDIR /app

# --- builder ----------------------------------------------------------------
FROM base AS builder

ARG NODE_VERSION

RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends \
      build-essential git libpq-dev libyaml-dev xz-utils \
 && rm -rf /var/lib/apt/lists/*

# esbuild (via jsbundling-rails) needs Node and Yarn to bundle
# app/javascript. Neither reaches the runtime image.
RUN set -eux; \
    case "$(dpkg --print-architecture)" in \
      amd64) node_arch=x64 ;; \
      arm64) node_arch=arm64 ;; \
      *) echo "unsupported architecture" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${node_arch}.tar.xz" -o /tmp/node.tar.xz; \
    tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 --no-same-owner; \
    rm /tmp/node.tar.xz; \
    npm install -g yarn@1.22.22

COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle config set --local frozen true && bundle install && rm -rf "${BUNDLE_PATH}"/ruby/*/cache

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --network-timeout 600000

COPY . .

# `yarn build` bundles app/javascript into app/assets/builds, then Sprockets
# fingerprints everything into public/assets.
# SECRET_KEY_BASE only has to exist for the production environment to boot.
RUN SECRET_KEY_BASE=precompile-placeholder \
    RAILS_ENV=production \
    bundle exec rails assets:precompile

# --- runtime ----------------------------------------------------------------
FROM base AS runtime

ENV RAILS_ENV=production \
    RAILS_SERVE_STATIC_FILES=true \
    BUNDLE_WITHOUT="development test"

COPY --from=builder ${BUNDLE_PATH} ${BUNDLE_PATH}
COPY --from=builder --chown=rails:rails /app /app

RUN mkdir -p tmp/pids log && chown -R rails:rails tmp log

USER rails

EXPOSE 3000

HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=5 \
  CMD curl -fsS http://localhost:3000/health || exit 1

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
