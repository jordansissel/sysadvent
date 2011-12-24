#!/usr/bin/env ruby
#

require "erb"
require "yaml"

def hosts_by_label(label)
  hosts = []
  @host_labels.each { |host,labels|
    hosts << host if labels.include?(label)
  }
  return hosts
end

@host_labels = YAML::load(File.new("hostlabels.yaml"))
@label_checks = YAML::load(File.new("labelchecks.yaml"))

config_template = File.new("nagios.cfg.erb").read

# see ERB.new docs for 'trim_mode' for info on "%>" below
template =  ERB.new(config_template, nil, "%<>")
puts template.result
