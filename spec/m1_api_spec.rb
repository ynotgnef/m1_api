require 'spec_helper'
require_relative '../lib/m1_api.rb'

RSpec.describe M1API do

  m1 = M1API.new(ENV['M1_USERNAME'], ENV['M1_PASSWORD'])

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
        expect(m1.token).to be_instance_of(String)
      end
      
      it 'perserves the original config values after init' do
        expect(m1.api_configs[:authenticate][:body].match?(/<<<username>>>/)).to eq true
      end
    end
  end

  describe '#query_accounts' do
    context 'user has valid credentials defined in ENV' do

      it 'outputs a list of accounts associated with the account' do
        output = m1.query_accounts
        expect(output.keys[0]).to be_instance_of(String)
      end

    end
  end

  describe '#query_account_detail' do
    context 'user has valid credentials defined in ENV' do

      it 'outputs the bank id associated with the account' do
        account_id = m1.query_accounts.values[0]
        output = m1.query_account_detail(account_id)
        expect(output[account_id][:bank]).to be_instance_of(Hash)
      end

    end
  end

  describe '#deposit' do
    context 'user has a list of accounts' do
      account_id = m1.query_accounts.values[0]
      m1.query_account_detail(account_id)
      bank_id = m1.accounts_detail[account_id][:bank]['id']
      amount = "1.#{rand(0..99)}"

      it 'gets a success response on deposit' do # should check beforehand to see if deposit is even possible
        output = m1.deposit(account_id, bank_id, amount)
        expect(output[:body]['data']['createImmediateAchDeposit']['result']['didSucceed']).to eq true
      end

      it 'updates account detail with the transfer' do
        m1.query_account_detail(account_id)
        amount_listed = m1.accounts_detail[account_id][:transfers][0]['node']['amount']
        expect(amount.to_f).to eq amount_listed
      end

      it 'gets a success response on cancel' do
        transfer_id = m1.accounts_detail[account_id][:transfers][0]['node']['id']
        output = m1.deposit(account_id, bank_id, transfer_id, true)
        expect(output[:body]['data']['cancelAchTransfer']['result']['didSucceed']).to eq true
      end

    end
  end

  describe '#withdrawl' do
    context 'user has a list of accounts' do
      account_id = m1.query_accounts.values[0]
      m1.query_account_detail(account_id)
      bank_id = m1.accounts_detail[account_id][:bank]['id']
      amount = "1.#{rand(0..99)}"

      it 'gets a success response on withdraw' do # should check beforehand to see if withdraw is even possible
        output = m1.withdraw(account_id, bank_id, amount)
        expect(output[:body]['data']['createImmediateAchWithdrawal']['result']['didSucceed']).to eq true
      end

      it 'updates account detail with the transfer' do
        m1.query_account_detail(account_id)
        amount_listed = m1.accounts_detail[account_id][:transfers][0]['node']['amount']
        expect(amount.to_f).to eq amount_listed
      end

      it 'gets a success response on cancel' do
        transfer_id = m1.accounts_detail[account_id][:transfers][0]['node']['id']
        output = m1.withdraw(account_id, bank_id, transfer_id, true)
        expect(output[:body]['data']['cancelAchTransfer']['result']['didSucceed']).to eq true
      end

    end
  end
end