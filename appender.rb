require 'googleauth'
require 'google/apis/sheets_v4'

SPREADSHEET_KEY = ENV['SPREADSHEET_KEY'] || "1sTXPVwkmmlwae_sEpRVal4KKO3q-44nebelt22CgbmU"
TABLE_RANGE = ENV['TABLE_RANGE'] || "Sheet1!A1:B1"
KEYS_PATH = ENV['KEYS_PATH'] || 'keys/'

class Appender
  DEFAULT_SCOPE = [
    'https://www.googleapis.com/auth/drive',
    'https://spreadsheets.google.com/feeds/'
  ]
  def initialize()
    @service = get_service()
  end

  def get_credentials (json_key_path_or_io, scope = DEFAULT_SCOPE)
    if json_key_path_or_io.is_a?(String)
      open(json_key_path_or_io) do |f|
        get_credentials(f, scope)
      end
    else
      Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: json_key_path_or_io, scope: scope)
    end
  end

  def get_service ()
    credentials = get_credentials(KEYS_PATH + "google_service_account.json")
    service = Google::Apis::SheetsV4::SheetsService.new
    service.client_options.application_name = "TEST"
    service.authorization = credentials
    service
  end

  def append(row)
    vals = Google::Apis::SheetsV4::ValueRange.new()
    vals.values = [row]
    @service.append_spreadsheet_value(SPREADSHEET_KEY, TABLE_RANGE, vals, value_input_option: "USER_ENTERED")
  end

end
