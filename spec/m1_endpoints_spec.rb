require 'spec_helper'
require_relative '../lib/m1_api.rb'
require_relative '../lib/m1_api/yaml_helpers.rb'

RSpec.describe YamlHelpers do
  let(:yaml_helpers_class) { Class.new { include YamlHelpers } }

  describe '#load_yaml' do
    context 'path to a yaml file' do
      path = './spec/credentials.yml'
      it 'loads the yaml file into a hash' do
        yaml = YamlHelpers.load_yaml(path)
        expect(yaml).to eq({ M1_USERNAME: 'username', M1_PASSWORD: 'password' })
      end
    end
  end

  describe '.replace_dynamic_string' do
    context 'hash with dynamically defined values' do
      hash = {
        base_reference: 'replaced_base_reference',
        nested: {reference: 'replaced_nested_reference'},
        string_only: '<<<base_reference>>>:<<<nested reference>>>'
      }
      output = YamlHelpers.replace_dynamic_string(hash[:string_only], hash)
      it 'replaces strings with dynamic values' do
        expect(output).to eq 'replaced_base_reference:replaced_nested_reference'
      end
      it 'perserves the original string' do
        expect(hash[:string_only]).to eq '<<<base_reference>>>:<<<nested reference>>>'
      end
    end
  end

  describe '.replace_dynamic_array' do
    context 'hash with dynamically defined values' do
      hash = {
        base_reference: 'replaced_base_reference',
        nested: {reference: 'replaced_nested_reference'},
        array: [
          'abc:',
          '<<<base_reference>>>:<<<nested reference>>>'
        ]
      }
      output = YamlHelpers.replace_dynamic_array(hash[:array], hash)
      it 'replaces strings with dynamic values' do
        expect(output).to eq 'abc:replaced_base_reference:replaced_nested_reference'
      end
      it 'perserves the original array' do
        expect(hash[:array]).to eq ['abc:', '<<<base_reference>>>:<<<nested reference>>>']
      end
    end
  end

  describe '.replace_dynamic_hash' do
    context 'hash with dynamically defined values' do
      hash = {
        base_reference: 'replaced_base_reference',
        nested: {reference: 'replaced_nested_reference'},
        hash: {
          string: '<<<base_reference>>>:<<<nested reference>>>',
          array: ['1', '<<<base_reference>>>']
        }
      }
      output = YamlHelpers.replace_dynamic_hash(hash[:hash], hash)
      expected_string = 'replaced_base_reference:replaced_nested_reference'
      expected_array = '1replaced_base_reference'
      it 'replaces hash values with dynamic values' do
        expect(output).to eq({ string: expected_string, array: expected_array })
      end
      it 'does not perserve the original hash' do
        expect(hash[:hash]).to eq({ string: expected_string, array: expected_array })
      end
    end
  end  

  describe '.call_api_from_yml' do
    context 'api call configs in yaml file' do
      it 'makes a get call' do
        output = YamlHelpers.call_api_from_yml('./lib/m1_api/api_configs.yml', 'test_get')
        expect(output[:code]).to eq 200
      end
      it 'makes a post call' do
        credentials = { username: 'username', password: 'password' }
        output = YamlHelpers.call_api_from_yml('./lib/m1_api/api_configs.yml', 'authenticate', credentials)
        expect(output[:code]).to eq 200
      end
    end
  end
end

RSpec.describe M1API do

  M1 = M1API.new(ENV['M1_USERNAME'], ENV['M1_PASSWORD'])

  describe '.read_credentials' do
    context 'user has valid credentials' do
      credentials_file = './spec/credentials.yml'
      it 'reads credentials from file' do
        credentials = M1API.read_credentials(credentials_file)
        expect(credentials[:username].is_a?(String)).to eq true
        expect(credentials[:password].is_a?(String)).to eq true
      end
      it 'reads credentials from ENV' do
        credentials = M1API.read_credentials
        expect(credentials[:username]).to be_instance_of(String)
        expect(credentials[:password]).to be_instance_of(String)
      end
    end
  end

  describe '#new' do
    context 'user has initialized instance of M1 class' do
      it 'M1 instance contains auth token' do
        expect(M1.token).to be_instance_of(String)
      end
    end
  end

  describe '#query_accounts' do
    context 'user has valid credentials defined in ENV' do
      it 'outputs a list of accounts associated with the account' do
        output = M1.query_accounts
        output.each do |id, data|
          expect(id).to eq data['id']
        end
      end
    end
  end  
end