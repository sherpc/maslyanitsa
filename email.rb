# coding: utf-8
require 'httparty'

class Email
  BASE_URL = "https://api.sendgrid.com/api/mail.send.json"
  BODY_URL = ENV['CONFIRM_EMAIL_BODY_URL'] || 'https://raw.githubusercontent.com/sherpc/maslyanitsa/master/README.md'
  SUBJECT = ENV['CONFIRM_EMAIL_SUBJECT'] || 'Подтверждение заявки. Рождественка'

  def send(message)
    email = message[3] ## id, timestamp, name, email

    return if email.nil? or email == ""

    post_to_sendgrid(email)
  end

  def debug
    # get_body()
    post_to_sendgrid('aleksandrsher@gmail.com')
  end

  private

  def post_to_sendgrid(to)
    send_via_sendgrid(to, SUBJECT, get_body())
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
      "api_user" => "maslyanitsa",
      "api_key" => "Maslyanitsa1",
      "to" => to,
      "subject" => subject,
      "html" => body,
      "text" => strip(body),
      "from" => "reg@rozhdestvenka.ru",
      "headers" => '{"X-Mailer": "Rozhdestvenka Mail Sender", "X-Mailru-Msgtype": "maslo"}'
    }

    response = HTTParty.post(BASE_URL, body: payload)
    return response.code == 200
  end

  def strip(s)
    return s.gsub(/<[^>]*>?/, '')
  end
end
