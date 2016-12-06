# coding: utf-8
require './appender.rb'
require 'thread'

def get_timestamp
  Time.now.strftime("%d.%m.%Y %H:%M:%S")
end

class Inc
  COUNTER_PATH = 'counter'

  def next()
    previous = File.exists?(COUNTER_PATH) ? File.read(COUNTER_PATH).to_i : 0;
    result = previous + 1
    File.write(COUNTER_PATH, result)
    result
  end
end

class InputQueueFetcher

  def initialize(input_queue, output_file_path, next_queue)
    @input_queue = input_queue
    @next_queue = next_queue
    @inc = Inc.new()

    @output_file_path = output_file_path
  end

  def process
    return if @input_queue.empty?

    message = @input_queue.pop
    message.insert(0, get_timestamp().to_s)
    message.insert(0, @inc.next().to_s)

    row = message
            .map { |v| v.gsub('"', ' ') }
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

  def initialize(input_queue)
    @input_queue = input_queue
    @appender = Appender.new()
  end

  def process
    return if @input_queue.empty?

    message = @input_queue.pop

    begin
      @appender.append(message)
    rescue Exception
      @input_queue << message
      raise
    end
  end
end
