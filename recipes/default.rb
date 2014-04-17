#
# Cookbook Name:: vms
# Recipe:: default
#
# Copyright 2013, Gridcentric Inc.
#

::Chef::Recipe.send(:include, Gridcentric)

# Resolve aliases for attributes.
if node.has_key?("vms")
  if node["vms"].has_key?("os-version")
    Chef::Log.warn("Node attribute node['vms']['os-version'] " +
                   "is DEPRECATED, use node['gridcentric']['os-version'] instead.")
    node.default["gridcentric"]["os-version"] = node["vms"]["os-version"]
  end
  if node["vms"].has_key?("repo") and node["vms"]["repo"].has_key?("url")
    Chef::Log.warn("Node attribute node['vms']['repo']['url'] " +
                   "is DEPRECATED, use node['gridcentric']['repo']['base-uri'] instead.")
    node.default["gridcentric"]["repo"]["base-uri"] = node["vms"]["repo"]["url"]
  end
  if node["vms"].has_key?("repo") and node["vms"]["repo"].has_key?("private_key")
    Chef::Log.warn("Node attribute node['vms']['repo']['private_key'] " +
                   "is DEPRECATED, use node['gridcentric']['repo']['vms']['key'] instead.")
    node.default["gridcentric"]["repo"]["vms"]["key"] = node["vms"]["repo"]["private_key"]
  end
end

if node["gridcentric"]["os-version"].nil?
  raise "Missing attribute: node['gridcentric']['os-version']. " +
    "This should be an Openstack release codename such as 'folsom'."
end

# Resolve base uris for all the components.
[ "agent", "cobalt", "cobaltclient", "vms" ].each do |component|
  if node["gridcentric"]["repo"][component]["uri"].nil?
    parts = [ node["gridcentric"]["repo"]["base-uri"].chomp("/"),
              node["gridcentric"]["repo"][component]["key"] ]
    if component == "vms"
      parts.push("vms")
    elsif component == "agent"
      parts.push("linux")
    else
      parts.push(node["gridcentric"]["os-version"])
    end
    parts.push(Repositories.translate_distro_to_repo_type(node["platform"],
                                        node["platform_version"], component,
                                        node["gridcentric"]["os-version"]))
    node.normal["gridcentric"]["repo"][component]["uri"] = parts.join("/")
  end
end

if node["gridcentric"]["repo"]["key-uri"].nil?
  node.normal["gridcentric"]["repo"]["key-uri"] = [ node["gridcentric"]["repo"]["base-uri"].chomp("/"),
                                             "gridcentric.key"
                                            ].join("/")
end

if platform?("ubuntu")
  node.normal["gridcentric"]["repo"]["components"] = ["gridcentric", "multiverse"]
else
  node.normal["gridcentric"]["repo"]["components"] = ["gridcentric", "non-free"]
end
