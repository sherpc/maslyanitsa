# coding: utf-8
require './appender.rb'
require './email.rb'
require 'thread'

TIMEZONE_CORRECTION = (ENV['TIMEZONE_CORRECTION'] || '0').to_i
COUNTER_PATH = ENV['COUNTER_PATH'] || 'counter'

def get_timestamp
  (Time.now + TIMEZONE_CORRECTION * 3600).strftime("%d.%m.%Y %H:%M:%S")
end

class Inc
  def next()
    previous = File.exists?(COUNTER_PATH) ? File.read(COUNTER_PATH).to_i : 0
    result = previous + 1
    File.write(COUNTER_PATH, result)
    result
  end
end

class InputQueueFetcher

  def initialize(input_queue, output_file_path, next_queue, logger)
    @input_queue = input_queue
    @next_queue = next_queue
    @inc = Inc.new()
    @logger = logger

    @output_file_path = output_file_path
  end

  def process
    return if @input_queue.empty?

    message = @input_queue.pop
    message.insert(0, get_timestamp().to_s)
    message.insert(0, @inc.next().to_s)

    @logger.info "get message #{message[0]} in input fetcher"

    row = message
            .map { |v| v.to_s.gsub('"', ' ') }
            .map { |v| "\"#{v}\"" }
            .join(",")

    open(@output_file_path, 'a') do |output|
      output.puts(row)
    end
    @next_queue << message
  end

  def close
    @output.close
  end
end

class GoogleQueueFetcher

  def initialize(input_queue, next_queue, logger)
    @input_queue = input_queue
    @logger = logger
    @appender = Appender.new()
    @next_queue = next_queue
  end

  def process
    return if @input_queue.empty?

    message = @input_queue.pop
    @logger.info "get message #{message[0]} in google fetcher"

    begin
      @appender.append(message)
    rescue Exception => e
      @input_queue << message
      @logger.error e
      raise
    end

    @next_queue << message
  end
end

class ConfirmationEmailQueueFetcher
  def initialize(input_queue, logger)
    @input_queue = input_queue
    @logger = logger
    @email = Email.new(@logger)
  end

  def process
    return if @input_queue.empty?

    message = @input_queue.pop
    @logger.info "get message #{message[0]} in email fetcher"

    begin
      result = @email.send(message)
      unless result
        @logger.error "can't send #{message}"
      end
    rescue Exception => e
      @input_queue << message
      @logger.error e
      raise
    end
  end
end
