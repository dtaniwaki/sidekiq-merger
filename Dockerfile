FROM ruby:2.3.3
MAINTAINER dtaniwaki

ENV PORT 3000
ENV REDIS_HOST 127.0.0.1
ENV REDIS_PORT 6379

RUN gem install bundler
ADD . /gem
WORKDIR /gem/app
RUN bundle install -j4

EXPOSE $PORT
