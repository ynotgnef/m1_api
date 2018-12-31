require 'spec_helper'
require_relative '../lib/m1_api.rb'

RSpec.describe M1API do

  describe '.load_yaml' do
    context 'path to a yaml file' do
      path = './spec/credentials.yml'
      it 'loads the yaml file into a hash' do
        yaml = M1API.load_yaml(path)
        expect(yaml).to eq({ M1_USERNAME: 'username', M1_PASSWORD: 'password' })
      end
    end
  end

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


  describe '.replace_dynamic_string' do
    context 'hash with dynamically defined values' do
      hash = {
        base_reference: 'replaced_base_reference',
        nested: {reference: 'replaced_nested_reference'},
        string_only: '<<<base_reference>>>:<<<nested reference>>>'
      }
      output = M1API.replace_dynamic_string(hash[:string_only], hash)
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
      output = M1API.replace_dynamic_array(hash[:array], hash)
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
      output = M1API.replace_dynamic_hash(hash[:hash], hash)
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
        output = M1API.call_api_from_yml('./lib/m1_api/api_configs.yml', 'test_get')
        expect(output[:code]).to eq 200
      end
      it 'makes a post call' do
        credentials = { username: 'username', password: 'password' }
        output = M1API.call_api_from_yml('./lib/m1_api/api_configs.yml', 'authenticate', credentials)
        expect(output[:code]).to eq 200
      end
    end
  end

  describe '.authenticate' do
    context 'user has valid credentials defined in ENV' do
      it 'outputs a response with an auth token' do
        output = M1API.authenticate
        expect(output).to be_instance_of(String)
      end
    end
  end
end