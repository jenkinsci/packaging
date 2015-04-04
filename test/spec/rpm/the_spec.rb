require_relative '../spec_helper.rb'

describe package('jenkinstest') do
  it { should be_installed }
end
