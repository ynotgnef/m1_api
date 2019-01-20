require 'spec_helper'
require_relative '../lib/m1_api/maintenance_helpers.rb'

RSpec.describe MaintenanceHelpers do
  let(:maintenance_helpers_class) { Class.new { include MaintenanceHelpers } }

  path = './spec/test.har'
  har = MaintenanceHelpers.load_har(path)

  describe '.load_har' do
    it 'loads the har file into a hash' do
      expect(har[0][:request][:url]).to eq('https://en.wikipedia.org/w/api.php?action=opensearch&format=json&formatversion=2&search=k&namespace=0&limit=10&suggest=true')
    end
  end

  describe '.filter_by_top_value' do
    it 'filters based on a top level string' do
      string_filter = MaintenanceHelpers.filter_by_top_value(har, :url, 'search=k')
      expect(string_filter.length).to eq 1
    end
    it 'filters based on a top level regex' do
      regex_filter = MaintenanceHelpers.filter_by_top_value(har, :url, /search=k/)
      expect(regex_filter.length).to eq 1
    end
    it 'perserves the original hash' do
      expect(har.length).to eq 2
    end
  end

end