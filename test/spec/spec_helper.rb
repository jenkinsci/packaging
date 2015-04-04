require 'serverspec'
require 'net/ssh'

# Including these at a top level to make sure we have some methods for our DSL
# that we need for server spec
include SpecInfra::Helper::Ssh
include SpecInfra::Helper::DetectOS
