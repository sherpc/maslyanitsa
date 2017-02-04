# coding: utf-8
require 'httparty'
require 'set'

class PersistentSet
  def initialize(path)
    @path = path
    @set = File.exists?(path) ? File.readlines(@path).map(&:strip).to_set : Set.new()
  end

  def contains?(x)
    return @set.include?(x)
  end

  def add(x)
    open(@path, 'a') { |f|
      f.puts(x)
    }
    @set.add(x)
  end
end

class Email
  BASE_URL = "https://api.sendgrid.com/api/mail.send.json"
  BODY_URL = ENV['CONFIRM_EMAIL_BODY_URL'] || 'http://rozhdestvenka.ru/maslo2017/confirm_email3.htm' # 'https://raw.githubusercontent.com/sherpc/maslyanitsa/master/confirm_email.txt'
  SUBJECT = ENV['CONFIRM_EMAIL_SUBJECT'] || 'Подтверждение заявки. Рождественка'
  SENT_LOG_PATH = ENV['SENT_LOG_PATH'] || 'sent_emails.log'
  WHITE_LIST = ENV['WHITE_LIST'] || ''
  SG_LOGIN = ENV['SG_LOGIN']
  SG_PASS = ENV['SG_PASS']
  SG_FROM = ENV['SG_FROM']

  def initialize(logger)
    @log = PersistentSet.new(SENT_LOG_PATH)
    @whitelist = WHITE_LIST.split(',').to_set
    logger.info("Email started with whitelist #{@whitelist}")
  end

  def send(message)
    ## id, timestamp, name, email
    name = message[2]
    email = message[3] 

    return :alredy_sent if email.nil? or email == "" or @log.contains?(email)

    result = post_to_sendgrid(email, name)
    @log.add(email) unless @whitelist.include?(email)
    return result
  end

  def debug
    get_body()
    # post_to_sendgrid('aleksandrsher@gmail.com', 'aleks')
    # send([0, 0, 'Алекс', 'aleksandrsher@gmail.com'])
  end

  private

  def post_to_sendgrid(to, name)
    body = get_body().sub("{name}", name)
    return send_via_sendgrid(to, SUBJECT, body)
  end

  def get_body()
    response = HTTParty.get(BODY_URL)
    if response.code != 200
      raise "Can't get body template. Code #{response.code}, body #{response.body}"
    end
    return response.body
  end

  def send_via_sendgrid(to, subject, body)
    payload = {
      "api_user" => SG_LOGIN,
      "api_key" => SG_PASS,
      "to" => to,
      "subject" => subject,
      "html" => body,
      "text" => strip(body),
      "from" => SG_FROM,
      "headers" => '{"X-Mailer": "Rozhdestvenka Mail Sender", "X-Mailru-Msgtype": "maslo"}'
    }

    response = HTTParty.post(BASE_URL, body: payload)
    return response.code == 200
  end

  def strip(s)
    return s.gsub(/<[^>]*>?/, '')
  end
end
