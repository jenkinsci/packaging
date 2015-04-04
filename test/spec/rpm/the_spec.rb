require_relative '../spec_helper.rb'

describe package('jenkinstest') do
  it { should be_installed }
end

describe service('jenkinstest') do
  it { should be_running }
end

describe port(ENV['PORT']) do
  it { should be_listening }
end
