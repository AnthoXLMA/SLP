FROM ruby:3.0.3 AS build

RUN set -e; \
  curl -fsSL https://deb.nodesource.com/setup_14.x | bash -; \
  apt-get install -y nodejs; \
  rm -rf /var/lib/apt/lists/*; \
  npm install --global yarn; \
  gem install bundler

RUN set -e; \
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -; \
  echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" | tee  /etc/apt/sources.list.d/pgdg.list; \
  apt-get update; \
  apt-get install -y postgresql-client-12; \
  rm -rf /var/lib/apt/lists/*

WORKDIR /usr/app

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

COPY Gemfile Gemfile.lock ./
# throw errors if Gemfile has been modified since Gemfile.lock
ENV BUNDLE_FROZEN=1
RUN set -e; \
  bundle install; \
  bundle list

COPY . .

ARG RAILS_MASTER_KEY
ENV RAILS_MASTER_KEY=${RAILS_MASTER_KEY}

ARG GIT_SHA1
ENV GIT_SHA1=${GIT_SHA1}

ARG SENTRY_DSN
RUN DOCKER_DISABLE_SMTP=1 RAILS_ENV=production NODE_ENV=production SENTRY_DSN=${SENTRY_DSN} bin/webpack

###############################################################################
FROM ruby:3.0.3 AS release

RUN gem install bundler

WORKDIR /usr/app
RUN set -e; \
  mkdir tmp log; \
  chmod a+rwt tmp log 

COPY Gemfile Gemfile.lock ./
# throw errors if Gemfile has been modified since Gemfile.lock
ENV BUNDLE_FROZEN=1
ENV BUNDLE_WITHOUT=development:test
RUN set -e; \
  bundle install; \
  bundle list

COPY --from=build /usr/app/Rakefile /usr/app/config.ru ./
COPY --from=build /usr/app/app/ /usr/app/app/
COPY --from=build /usr/app/config/ /usr/app/config/
COPY --from=build /usr/app/lib/ /usr/app/lib/
COPY --from=build /usr/app/public/ /usr/app/public/

# regenerate binstubs without spring
RUN bundle binstubs railties

USER 1001

ARG RAILS_MASTER_KEY
ENV RAILS_MASTER_KEY=${RAILS_MASTER_KEY}

ARG GIT_SHA1
ENV GIT_SHA1=${GIT_SHA1}

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
