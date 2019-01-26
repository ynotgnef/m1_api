require_relative './m1_api/yaml_helpers.rb'

# open browser
# open network logs
# save entire thing as har
# parse
# should match the logs against when the actions were performed

class M1API
#  autoload :CLI, 'm1_api/cli'
  autoload :VERSION, 'm1_api/version'

  attr_accessor :api_config_file, :api_configs, :token, :accounts, :accounts_detail
  

  def output(string)
    puts string
  end

  def initialize(username, password, api_config_file = "#{__dir__}/m1_api/api_configs.yml")
    @accounts = {}
    @accounts_detail = {}
    load_config_file(api_config_file)
    credentials = { username: username, password: password }
    res = YamlHelpers.call_api_from_config(@api_configs, :authenticate, credentials)
    raise "failed to authenticate:\n\t#{res}" unless res[:code] == 200 && res[:body]['data']['authenticate']['result']['didSucceed']
    @token = res[:body]['data']['authenticate']['accessToken'] 
  end

  def load_config_file(api_config_file)
    # change it to reject both if either fails
    @api_config_file = api_config_file
    @api_configs = YamlHelpers.load_yaml(@api_config_file)
  end

  def self.read_credentials(credentials_file=nil)
    if credentials_file
      credentials = YamlHelpers.load_yaml(credentials_file)
      { username: credentials[:M1_USERNAME], password: credentials[:M1_PASSWORD] }
    else
      {username: ENV['M1_USERNAME'], password: ENV['M1_PASSWORD']}
    end
  end

  def query_accounts
    accounts = {}
    data = { token: @token }
    id_res = YamlHelpers.call_api_from_config(@api_configs, :list_account_ids, data)
    ids = id_res[:body]['data']['viewer']['accounts']['edges'].each do |account|
      accounts[account['node']['nickname']] = account['node']['id']
    end
    @accounts = accounts
  end

  def query_account_detail(account_id)
    data = { token: @token, account_id: account_id }
    detail = YamlHelpers.call_api_from_config(@api_configs, :query_account_detail, data)[:body]['data']['node']
    @accounts_detail[account_id] = {
      status: detail['status'],
      bank: detail['lastAchRelationship'],
      transfers: detail['_achTransfers']['edges']
    }
    @accounts_detail
  end

  def deposit(account_id, bank_id, transaction, cancel = false)
    if cancel
      data = { token: @token, account_id: account_id, bank_id: bank_id, transfer_id: transaction }
      YamlHelpers.call_api_from_config(@api_configs, :cancel_deposit, data)
    else
      data = { token: @token, account_id: account_id, bank_id: bank_id, amount: transaction }
      YamlHelpers.call_api_from_config(@api_configs, :deposit, data)
    end
  end

  def withdraw(account_id, bank_id, transaction, cancel = false)
    if cancel
      data = { token: @token, account_id: account_id, bank_id: bank_id, transfer_id: transaction }
      YamlHelpers.call_api_from_config(@api_configs, :cancel_withdraw, data)
    else
      data = { token: @token, account_id: account_id, bank_id: bank_id, amount: transaction }
      YamlHelpers.call_api_from_config(@api_configs, :withdraw, data)
    end
  end
end