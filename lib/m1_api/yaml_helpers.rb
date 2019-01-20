require 'yaml'
require 'erb'
require 'rest-client'
require 'json'

module YamlHelpers
  module_function

  def load_yaml(file_path)
    YAML.load(ERB.new(File.read(file_path)).result) || {}
  rescue SystemCallError
    raise "Could not load file: '#{file_path}"
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
        if value.is_a?(String)
          dup[index] = replace_dynamic_string(value, context)
        elsif value.is_a?(Array)
          dup[index] = replace_dynamic_array(value, context)
        elsif value.is_a?(Hash)
          dup[index] = replace_dynamic_hash(value, context)
        end
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

    def call_api_from_config(configs, api, data = {})
      config = configs[api].dup
      raise "no api defined for #{api}" unless config
      context = config.merge data
      parsed_config = replace_dynamic_hash(context)
      params = [parsed_config[:method], parsed_config[:url], parsed_config[:body], parsed_config[:headers]]
      params.delete(nil)
      res = RestClient.send(*params)
      { code: res.code, body: JSON.parse(res.body) }
    rescue Exception => e
      return { code: res.code, body: res.body } if res
      puts "failed to call api for api #{api}: #{e}"
    end

    def call_api_from_yml(config_file, api, data = {})
      configs = load_yaml(config_file)
      call_api_from_config(configs, api, data)
    end
end