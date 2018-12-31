name = "m1_api"
require "./lib/#{name}/version"

Gem::Specification.new name, M1API::VERSION do |s|
    s.summary = 'Access M1 Finance functionalities via API'
    s.authors = ["Yuan Feng"]
    s.email = "thefunkyphresh@gmail.com"
    s.homepage = "http://github.com/ynot_gnef/m1_api"
    s.files = Dir["{lib,bin}/**/*"] + ["Readme.md"]
    s.license = "MIT"
    s.executables = ["m1_api_generate"]
    s.add_runtime_dependency 'rest-client'
    s.add_runtime_dependency 'json'
    s.required_ruby_version = '>= 2.2.0'
  end