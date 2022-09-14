# -----------
# Stage Base.
# -----------
FROM ruby:3.1.2-alpine3.16 as base

LABEL company="clicksign"
LABEL maintainer="Team Devops"

RUN apk update --no-cache \
  && apk upgrade --no-cache \
  && apk add --no-cache \
  postgresql

# --------------
# Stage Builder.
# --------------
FROM ruby:3.1.2-alpine3.16 as builder

RUN apk add --update --no-cache \
    build-base \
    postgresql-dev

ENV APP_HOME /clicksign-api-tracer-bullet
WORKDIR $APP_HOME

# ===> Setup and Bundle Install
COPY Gemfile* ./
ENV RAILS_ENV production
RUN  bundle install --jobs=4 --without development test
COPY . $APP_HOME
RUN rm -rf $APP_HOME/tmp/*
# ===> End Setup and Bundle Install

# -----------
# Stage Prod.
# -----------
FROM base

ENV RAILS_ENV=production
ENV APP_USER=clicksign
ENV APP_GROUP=clicksign
ENV RAILS_LOG_TO_STDOUT="true"

# Create a non-root user to run the app and own app-specific files
RUN adduser -D $APP_USER

# Switch to this user
USER $APP_USER

# We'll install the app in this directory
ENV APP_HOME /clicksign-api-tracer-bullet
WORKDIR $APP_HOME

COPY --from=builder /usr/local/bundle/ /usr/local/bundle/
COPY --from=builder --chown=$APP_USER:$APP_GROUP $APP_HOME $APP_HOME

RUN mkdir -p tmp/pids && rm -rf vendor/

CMD [ "bin/rails", "s" ]
