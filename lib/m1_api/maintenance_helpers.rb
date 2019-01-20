require 'json'

# need some semi automated way of maintaining apis as they change
# start selenium web session, authenticate manually, then run scripts to go through flows
# parse the generated .har file and compare against current api configs file
# might have to do fuzzy matching of the schema?

# create git conflict for each call list as an accept/reject

# to do the replace string, should convert this to a class

module MaintenanceHelpers
  module_function

  def load_har(path_to_file)
    out = []
    JSON.parse(File.read(path_to_file))['log']['entries'].each do |call|
      out << {
        start_time: call['startTime'],
        request: {
          method: call['request']['method'],
          url: call['request']['url'],
          headers: call['request']['headers'],
          body: call['request']['postData']
        },
        response: {
          status: call['response']['status'],
          content: call['response']['content']
        }
      }
    end
    out
  end

  def filter_by_top_value(calls, key, value)
    if value.is_a? Regexp
      calls.select { |call| call if call[:request][key].match?(value) }
    else
      calls.select { |call| call if call[:request][key].include?(value) }
    end
  end

  def replace_value_with_key(data, matcher, key)

  end
end