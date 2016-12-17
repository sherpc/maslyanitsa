# coding: utf-8
require './fetchers.rb'
require 'rufus/scheduler'
require 'sinatra'
require 'sinatra/base'
require 'sinatra/cross_origin'
require 'json'
require 'logger'

RUN_INPUT_FETCHER_EVERY = ENV['RUN_INPUT_FETCHER_EVERY'] || '0.3s'
RUN_GOOGLE_FETCHER_EVERY = ENV['RUN_GOOGLE_FETCHER_EVERY'] || '1s'
WAL_PATH = ENV['WAL_PATH'] || 'out.txt'
LOGGER_LEVEL = ENV['LOG_DEBUG'] == 'true' ? Logger::DEBUG : Logger::WARN

$input_queue = Queue.new()
$google_queue = Queue.new()
$logger = Logger.new(STDOUT)
$logger.level = LOGGER_LEVEL

# Init scheduler
def run_scheduler
  scheduler = Rufus::Scheduler.new
  fetcher = InputQueueFetcher.new($input_queue, WAL_PATH, $google_queue, $logger)
  google_fetcher = GoogleQueueFetcher.new($google_queue, $logger)

  scheduler.every RUN_INPUT_FETCHER_EVERY do
    fetcher.process()
  end

  scheduler.every RUN_GOOGLE_FETCHER_EVERY do
    fetcher.process()
    google_fetcher.process()
  end
end

run_scheduler()
$logger.info "##### Scheduler started with WAL in #{WAL_PATH} #####"

# Web

class App < Sinatra::Base
  configure :production, :development do
    enable :logging
  end

  post '/application' do
    [400, {}, {}] unless request.form_data?
    response.headers['Access-Control-Allow-Origin'] = '*'
    message = params.values
    $input_queue << message
    content_type :json
    message.to_json
  end

  get '/queues' do
    content_type :json
    {:input => $input_queue.length, :google => $google_queue.length}.to_json
  end
end


## test

def test
  $input_queue << ["test", (rand()*100).to_i]
  $input_queue << ["еще один", "день", (rand()*100).to_i]
end
