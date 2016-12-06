# coding: utf-8
require './fetchers.rb'
require 'rufus/scheduler'

RUN_INPUT_FETCHER_EVERY = ENV['WRITE_METRICS_EVERY'] || '5s'
RUN_GOOGLE_FETCHER_EVERY = ENV['WRITE_METRICS_EVERY'] || '5s'

$app = Appender.new()
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
    google_fetcher.process()
  end
end

## test

def test
  $input_queue << ["test", (rand()*100).to_i]
  $input_queue << ["еще один", "день", (rand()*100).to_i]
end

