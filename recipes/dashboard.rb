#
# Cookbook Name:: vms
# Recipe:: dashboard
#
# Copyright 2012, Gridcentric Inc.
#

include_recipe "apt"
include_recipe "vms::client"
::Chef::Recipe.send(:include, Gridcentric)

if not platform?("ubuntu")
  raise "Unsupported platform: #{node["platform"]}"
end

apt_repository "gridcentric-#{node["vms"]["os-version"]}" do
  uri Vms::Helpers.construct_repo_uri(node["vms"]["os-version"], node)
  components ["gridcentric", "multiverse"]
  key Vms::Helpers.construct_key_uri(node)
  notifies :run, resources(:execute => "apt-get update"), :immediately
  only_if { platform?("ubuntu") }
end

if ["folsom", "essex", "diablo"].include?(node["vms"]["os-version"])
  package "horizon-gridcentric" do
    action :upgrade
    options "-o APT::Install-Recommends=0"
  end
else
  package "cobalt-horizon" do
    action :upgrade
    options "-o APT::Install-Recommends=0"
  end
end
