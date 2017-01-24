# coding: utf-8
require './fetchers.rb'
require 'rufus/scheduler'
require 'sinatra'
require 'sinatra/base'
require 'sinatra/param'
require 'sinatra/cross_origin'
require 'json'
require 'logger'

RUN_INPUT_FETCHER_EVERY = ENV['RUN_INPUT_FETCHER_EVERY'] || '0.3s'
RUN_GOOGLE_FETCHER_EVERY = ENV['RUN_GOOGLE_FETCHER_EVERY'] || '1s'
WAL_PATH = ENV['WAL_PATH'] || 'out.txt'
LOGGER_LEVEL = ENV['LOG_DEBUG'] == 'true' ? Logger::DEBUG : Logger::WARN
VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

$input_queue = Queue.new()
$google_queue = Queue.new()
$logger = Logger.new('/tmp/stdout')
$logger.level = LOGGER_LEVEL
$logger.info "##### Logger started #####"

# Init scheduler
def run_scheduler
  scheduler = Rufus::Scheduler.new
  fetcher = InputQueueFetcher.new($input_queue, WAL_PATH, $google_queue, $logger)
  google_fetcher = GoogleQueueFetcher.new($google_queue, $logger)

  scheduler.every RUN_INPUT_FETCHER_EVERY, :overlap => false do
    fetcher.process()
  end

  scheduler.every RUN_GOOGLE_FETCHER_EVERY, :overlap => false do
    google_fetcher.process()
  end
end

run_scheduler()
$logger.info "##### Scheduler started with WAL in #{WAL_PATH} #####"

# Web

class App < Sinatra::Base

  helpers Sinatra::Param

  before do
    content_type :json
  end

  configure :production, :development do
    enable :logging
  end

  post '/application' do
    [400, {}, {}] unless request.form_data?
    param :name, String, required: true, blank: false, max_length: 150
    param :email, String, required: true, blank: false, max_length: 100, format: VALID_EMAIL_REGEX
    param :people, Integer, required: true, min: 0, max: 100
    param :experience, Integer, required: true, min: 0, max: 100
    param :new, Integer, required: true, min: 0, max: 100
    param :children, Integer, required: true, min: 0, max: 100
    param :club, String, required: true, max_length: 150
    param :comment, String, required: true, max_length: 500

    response.headers['Access-Control-Allow-Origin'] = '*'
    message = [
      params[:name],
      params[:email],
      params[:people],
      params[:experience],
      params[:new],
      params[:children],
      params[:club],
      params[:comment]
    ]
    $input_queue << message
    message.to_json
  end

  get '/queues' do
    response.headers['Access-Control-Allow-Origin'] = '*'
    {:input => $input_queue.length, :google => $google_queue.length}.to_json
  end
end


## test

def test
  $input_queue << ["test", (rand()*100).to_i]
  $input_queue << ["еще один", "день", (rand()*100).to_i]
end
