#
# Cookbook Name:: vms
# Recipe:: client
#
# Copyright 2012, Gridcentric Inc.
#

include_recipe "vms"

if platform?("ubuntu")
  include_recipe "apt"
  apt_repository "gridcentric-cobaltclient" do
    uri node["gridcentric"]["repo"]["cobaltclient"]["uri"]
    components node["gridcentric"]["repo"]["components"]
    key node["gridcentric"]["repo"]["key-uri"]
    notifies :run, resources(:execute => "apt-get update"), :immediately
  end
elsif platform_family?("rhel")
  yum_repository "gridcentric-cobaltclient" do
    url node["gridcentric"]["repo"]["cobaltclient"]["uri"]
    gpgkey node["gridcentric"]["repo"]["key-uri"]
    action :add
  end
else
  raise "Unsupported platform: #{node["platform"]}"
end

package "cobalt-novaclient" do
  action :upgrade
  if platform?("ubuntu")
    options "-o APT::Install-Recommends=0"
  end
end
