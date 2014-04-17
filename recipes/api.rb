#
# Cookbook Name:: vms
# Recipe:: api
#
# Copyright 2012, Gridcentric Inc.
#

include_recipe "vms"

if platform?("ubuntu")
  include_recipe "apt"
  apt_repository "gridcentric-cobalt" do
    uri node["gridcentric"]["repo"]["cobalt"]["uri"]
    components node["gridcentric"]["repo"]["components"]
    key node["gridcentric"]["repo"]["key-uri"]
    notifies :run, resources(:execute => "apt-get update"), :immediately
  end
elsif platform_family?("rhel")
  yum_repository "gridcentric-cobalt" do
    url node["gridcentric"]["repo"]["cobalt"]["uri"]
    gpgkey node["gridcentric"]["repo"]["key-uri"]
  end
else
  raise "Unsupported platform: #{node["platform"]}"
end

if ["folsom", "essex", "diablo"].include?(node["gridcentric"]["os-version"])
  package "nova-api-gridcentric" do
    action :upgrade
    if platform?("ubuntu")
      options "-o APT::Install-Recommends=0"
    end
  end
else
  package "cobalt-api" do
    action :upgrade
    if platform?("ubuntu")
      options "-o APT::Install-Recommends=0"
    end
  end
end

