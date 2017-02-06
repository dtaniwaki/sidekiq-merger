FROM ruby:2.3.3
MAINTAINER dtaniwaki

ENV PORT ${PORT:-3000}

RUN chmod 777 -R /tmp && chmod o+t -R /tmp
RUN gem install bundler
ADD . /gem
WORKDIR /gem/app
RUN bundle install -j4

ENTRYPOINT ["/bin/bash", "-c"]

EXPOSE 3000
