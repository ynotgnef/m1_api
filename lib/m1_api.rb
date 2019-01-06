require_relative './m1_api/yaml_helpers.rb'

class M1API
#  autoload :CLI, 'm1_api/cli'
  autoload :VERSION, 'm1_api/version'

  attr_accessor :api_config_file, :token

  api_config_file = "#{__dir__}/m1_api/api_configs.yml"

  def initialize(username, password, api_config_file = nil)
    @api_config_file = api_config_file || "#{__dir__}/m1_api/api_configs.yml"
    credentials = { username: username, password: password }
    res = YamlHelpers.call_api_from_yml(@api_config_file, 'authenticate', credentials)
    raise "failed to authenticate:\n\t#{res}" unless res[:code] == 200 && res[:body]['data']['authenticate']['result']['didSucceed']
    @token = res[:body]['data']['authenticate']['accessToken'] 
  end

  def self.read_credentials(credentials_file=nil)
    if credentials_file
      credentials = YamlHelpers.load_yaml(credentials_file)
      { username: credentials[:M1_USERNAME], password: credentials[:M1_PASSWORD] }
    else
      {username: ENV['M1_USERNAME'], password: ENV['M1_PASSWORD']}
    end
  end

  def check_status
    res = call_api_from_yml(@@api_config_file, 'check_status', token)
    puts res.inspect
  end

  def query_accounts
    accounts = {}
    data = { token: @token }
    id_res = YamlHelpers.call_api_from_yml(@api_config_file, 'list_account_ids', data)
    ids = id_res[:body]['data']['viewer']['_accounts1NFCow']['edges'].map { |account| account['node']['id'] }
    ids.each do |id|
      data[:account_id] = id
      account_res = YamlHelpers.call_api_from_yml(@api_config_file, 'query_account', data)
      accounts[id] = account_res[:body]['data']['node']
    end
    accounts
  end
end