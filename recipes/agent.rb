#
# Cookbook Name:: vms
# Recipe:: agent
#
# Copyright 2012, Gridcentric Inc.
#

include_recipe "vms"

# Add the appropriate source list based on the platform.
if platform?([ "ubuntu", "debian" ])
  include_recipe "apt"
  apt_repository "gridcentric-agent" do
    uri node["gridcentric"]["repo"]["agent"]["uri"]
    components node["gridcentric"]["repo"]["components"]
    key node["gridcentric"]["repo"]["key-uri"]
    notifies :run, resources(:execute => "apt-get update"), :immediately
  end
  package "linux-headers-#{node["kernel"]["release"]}" do
    action :upgrade
  end
elsif platform?([ "centos", "fedora" ])
  yum_repository "gridcentric-agent" do
    url node["gridcentric"]["repo"]["agent"]["uri"]
    gpgkey node["gridcentric"]["repo"]["key-uri"]
    action :add
  end
  package "kernel-devel" do
    action :upgrade
  end
else
  raise "Unsupported platform: #{node["platform"]}"
end

package "vms-agent" do
  action :upgrade
end
