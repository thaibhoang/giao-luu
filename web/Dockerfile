# syntax=docker/dockerfile:1
# check=error=true

# Production image (mặc định — stage cuối file):
#   docker build -t giao_luu -f web/Dockerfile web
#
# Image cho docker compose (development, đủ gem :development):
#   docker build --target development --build-arg DEV_IMAGE=true -f web/Dockerfile web
#
# Chạy production tay:
#   docker run -d -p 80:80 -e RAILS_MASTER_KEY=<từ config/master.key> --name giao_luu giao_luu

ARG RUBY_VERSION=3.4.1
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base_common

WORKDIR /rails

# Thống nhất với stage build + final (bundle install phải ghi vào đúng thư mục được COPY).
ENV BUNDLE_PATH="/usr/local/bundle"

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# --- Runtime: production (Kamal / deploy) ---
FROM base_common AS base_production
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

# --- Runtime: development (docker compose) — Bundler không deployment / không loại nhóm dev ---
FROM base_common AS base_development
ENV RAILS_ENV="development" \
    BUNDLE_PATH="/usr/local/bundle" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

# --- Build gems + app (hành vi phụ thuộc ARG DEV_IMAGE) ---
FROM base_common AS build
ARG DEV_IMAGE=false

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libvips libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./
RUN if [ "$DEV_IMAGE" = "true" ]; then \
      bundle install && \
      rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git; \
    else \
      bundle config set deployment 'true' && \
      bundle config set without 'development' && \
      bundle install && \
      rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git; \
    fi

RUN bundle exec bootsnap precompile -j 1 --gemfile

COPY . .

RUN bundle exec bootsnap precompile -j 1 app/ lib/

RUN SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production ./bin/rails assets:precompile

# --- Final: development (compose); đặt trước production để stage mặc định vẫn là production ---
FROM base_development AS development

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
USER 1000:1000

COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]

# --- Final: production (mặc định khi docker build không có --target) ---
FROM base_production AS production

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
USER 1000:1000

COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
