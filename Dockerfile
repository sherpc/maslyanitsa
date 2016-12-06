FROM ruby:2.3.1

COPY . /usr/src/app
RUN cd /usr/src/app && bundle install
WORKDIR /usr/src/app

EXPOSE 4567

CMD ["bundle","exec","rackup","config.ru","-p","4567","-s","thin","-o","0.0.0.0"]
