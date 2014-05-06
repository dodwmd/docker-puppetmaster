# a config.ru, for use with every rack-compatible webserver.
# SSL needs to be handled outside this, though.

$0 = "master"

# if you want debugging:
# ARGV << "--debug"

ARGV << "--rack"

ARGV << "--confdir" << "/etc/puppet"
ARGV << "--vardir"  << "/var/lib/puppet"

Encoding.default_external = Encoding::UTF_8

require 'puppet/util/command_line'
# we're usually running inside a Rack::Builder.new {} block,
# therefore we need to call run *here*.
run Puppet::Util::CommandLine.new.execute
