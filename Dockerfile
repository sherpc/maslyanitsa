FROM ruby:2.3.0-alpine

## forward logs
RUN ln -sf /dev/stdout /tmp/stdout

COPY . /usr/src/app

RUN \
    apk --update add bash g++ musl-dev make && \
    cd /usr/src/app && \
    bundle install

WORKDIR /usr/src/app

EXPOSE 4567

CMD bundle exec rackup config.ru -p 4567 -s thin -o 0.0.0.0
