require 'rest-client'
require 'json'
require 'yaml'
require 'erb'

###
### have to change yml paths to be relative from gem
###

module M1API
#  autoload :CLI, 'm1_api/cli'
  autoload :VERSION, 'm1_api/version'

  class << self
    def read_credentials(credentials_file=nil)
      if credentials_file
        credentials = load_yaml(credentials_file)
        { username: credentials[:M1_USERNAME], password: credentials[:M1_PASSWORD] }
      else
        {username: ENV['M1_USERNAME'], password: ENV['M1_PASSWORD']}
      end
    end

    def load_yaml(file_path)
      YAML.load(ERB.new(File.read(file_path)).result) || {}
    rescue SystemCallError
      raise "Could not load file: '#{file_path}"
    end

    def call_api(api_configs_file, api)
      raise 'nyi'
      api_config = load_yaml(api_configs_file)[api]
      raise "No api '#{api}' defined in '#{api_configs_file}'" unless api_config
      params = parse_api_config(api_config)
      JSON.parse(RestClient.send(params['method'], params['url']), params['body'], params['headers'])
    end

    # might have to convert everything to sym first
    def replace_dynamic_string(string, context)
      raise 'input is not a string' unless string.is_a?(String)
      replace_targets = string.split('>>>').map { |target| target.match(/<<<.*/).to_s }
      replace_targets.each do |target|
        key = target.match(/<<<(.*)/)
        if key
          temp_value = context
          key[1].split(' ').each do |current_key|
            raise "no value '#{current_key}' defined in  context" unless temp_value.key?(current_key.to_sym)
            temp_value = temp_value[current_key.to_sym]
          end
          string = string.gsub("#{target}>>>", temp_value)
        end
      end
      string
    end

    # need something to deal with uri encode
    def replace_dynamic_array(array, context)
      raise 'input is not a array' unless array.is_a?(Array)
      dup = array.clone
      dup.each_with_index do |value, index|
        dup[index] = replace_dynamic_string(value, context)
      end
      dup.join
    end

    def replace_dynamic_hash(hash, context = hash)
      raise 'input is not a hash' unless hash.is_a?(Hash)
      hash.each do |key, value|
        if value.is_a?(String)
          hash[key] = replace_dynamic_string(value, context)
        elsif value.is_a?(Array)
          hash[key] = replace_dynamic_array(value, context)
        elsif value.is_a?(Hash)
          hash[key] = replace_dynamic_hash(value, context)
        end
      end
      hash
    end

    def call_api_from_yml(config_file, api, data = {})
      config = load_yaml(config_file)[api.to_sym]
      raise "no api defined for #{api}" unless config
      context = config.merge data
      parsed_config = replace_dynamic_hash(context)
      params = [parsed_config[:method], parsed_config[:url], parsed_config[:body], parsed_config[:headers]]
      params.delete(nil)
      res = RestClient.send(*params)
      { code: res.code, body: JSON.parse(res.body) }
    rescue
      { code: res.code, body: res.body }
    end
    
    def authenticate(credentials_file = nil)
      credentials = read_credentials(credentials_file)
      res = call_api_from_yml('./lib/m1_api/api_configs.yml', 'authenticate', credentials)
      raise "failed to authenticate:\n\t#{res}" unless res[:code] == 200 && res[:body]['data']['authenticate']['result']['didSucceed']
      res[:body]['data']['authenticate']['accessToken']
    end
  end
end