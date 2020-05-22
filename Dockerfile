FROM ruby:2.5.5

LABEL maintainer='search@support.digitalgov.gov'

COPY Gemfile* /usr/src/app/
WORKDIR /usr/src/app
RUN bundle install

COPY config/secrets_example.yml config/secrets.yml
