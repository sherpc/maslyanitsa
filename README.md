# Сбор заявок на Масляницу

[![Build Status](https://travis-ci.org/sherpc/maslyanitsa.svg?branch=master)](https://travis-ci.org/sherpc/maslyanitsa)

## Архитектура

 - Все упаковано в docker контейнер, который экспоузит порт 4567. Также при старте можно указать много всяких разных конфигов (файл с ответами на форму, путь к ключам гугла, путь к логу и тд), см. docker-compose.yml для примеров
 - Сервер, написанный на Sinatra (main.rb, class App) -- слушает адреса POST /application (отправить ответ на форму) и GET /queues - служебный, показывает загруз очередей. Все, что сервер делает на /application -- кладет значения формы из http в виде массива в очередь $input_queue в памяти
 - Два разгребателя очередей, запускаются раз в N времени, N настраивается в конфиге (сами разгребатели -- в файле fetchers.rb, настройки запуска -- в main.rb):
   - input fetcher, берет сообщеньку из $input_queue, добавляет в массив в начало два элемента -- порядковый номер и таймстамп. Порядковый номер берется из файлика, увеличивается на 1 и записывается обратно в файл. На многопоточность тут кладется болт, потому что очередь мы разбираем одним потоком. После "обогащения" массива, он дописывается в лог-файл в csv формате, и пушится в google очередь
   - google fetcher, берет сообщеньку из google очереди и пытается записать её в гугл документ. Если происходит ошибка, отправляет обратно к себе в очередь
 - Для работы нужно добавить в гугл документ service account (то есть пошарить документ на почту сервис-аккаунта), а докеру указать путь с секретным файлом от гугла с ключами для доступа к api
 
### Формат входных данных POST /application

```
VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

param :name, String, required: true, blank: false, max_length: 150
param :email, String, required: true, blank: false, max_length: 100, format: VALID_EMAIL_REGEX
param :people, Integer, required: true, min: 0, max: 50
param :experience, Integer, required: true, min: 0, max: 40
param :new, Integer, required: true, min: 0, max: 30
param :children, Integer, required: true, min: 0, max: 10
param :club, String, required: true, max_length: 150
param :comment, String, required: true, max_length: 500
```
   
   
