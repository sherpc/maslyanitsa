# coding: utf-8
require './fetchers.rb'
require 'rufus/scheduler'
require 'sinatra'
require 'json'

RUN_INPUT_FETCHER_EVERY = ENV['WRITE_METRICS_EVERY'] || '1s'
RUN_GOOGLE_FETCHER_EVERY = ENV['WRITE_METRICS_EVERY'] || '1s'

$input_queue = Queue.new()
$google_queue = Queue.new()

# Init scheduler
def run_scheduler
  scheduler = Rufus::Scheduler.new
  fetcher = InputQueueFetcher.new($input_queue, "out.txt", $google_queue)
  google_fetcher = GoogleQueueFetcher.new($google_queue)

  scheduler.every RUN_INPUT_FETCHER_EVERY do
    fetcher.process()
  end

  scheduler.every RUN_GOOGLE_FETCHER_EVERY do
    puts "google"
    google_fetcher.process()
  end
end

run_scheduler()
puts "##### Scheduler started. #####"

# Web

post '/application' do
  [400, {}, {}] unless request.form_data?
  message = params.values
  $input_queue << message
  content_type :json
  message.to_json
end


## test

def test
  $input_queue << ["test", (rand()*100).to_i]
  $input_queue << ["еще один", "день", (rand()*100).to_i]
end
