#
# Cookbook Name:: vms
# Recipe:: compute
#
# Copyright 2012, Gridcentric Inc.
#

include_recipe "vms"

if platform?("ubuntu")
  include_recipe "apt"
  [ "vms", "cobalt" ].each do |repo|
    apt_repository "gridcentric-#{repo}" do
      uri node["gridcentric"]["repo"][repo]["uri"]
      components node["gridcentric"]["repo"]["components"]
      key node["gridcentric"]["repo"]["key-uri"]
    end
  end

  # Do this separately to avoid redundant updates, since we include
  # multiple repositories.
  execute "apt-get update" do
    command "apt-get update"
    action :run
  end
elsif platform_family?("rhel")
  [ "vms", "cobalt" ].each do |repo|
    yum_repository "gridcentric-#{repo}" do
      url node["gridcentric"]["repo"][repo]["uri"]
      gpgkey node["gridcentric"]["repo"]["key-uri"]
    end
  end
else
  raise "Unsupported platform: #{node["platform"]}"
end

# Workaround for 2.4 packaging bug. The 2.4 vms-libvirt package
# scripts refers to a script called 'start-stop-vmsmd' which it
# doesn't provide. This means start-stop-vmsmd can go missing, and
# this breaks the package uninstall scripts. As a workaround, this
# recipe checks to see if start-stop-vmsmd exists and creates a dummy
# script if it's missing. Note that the dummy script is simply an
# empty file and doesn't need to do anything for the uninstall to
# succeed.
execute "ensure start-stop-vmsmd" do
  command "[ -e /usr/sbin/start-stop-vmsmd ] || " +
    "(touch /usr/sbin/start-stop-vmsmd && chmod a+x /usr/sbin/start-stop-vmsmd)"
  action :run
end

# Explicitly upgrade vms low-level components
# We ship qemu-precise for precise, and quantal, as long as UCA points
# to Grizzly or lower. Otherwise distro qemu is fine and we need
# wrapper instead.
if platform?("ubuntu")
  if (node["platform_version"] == "12.04" ||
      node["platform_version"] == "12.10") &&
     ["folsom", "essex", "diablo", "grizzly"].include?(node["gridcentric"]["os-version"])
    qemu_package = "vms-qemu-precise"
  else
    qemu_package = "vms-qemu-wrapper"
  end
elsif platform_family?("rhel")
  # We don't have a host of choices here
  qemu_package = "vms-qemu-fc19"
end

if platform?("ubuntu")
  linux_headers_package = "linux-headers-#{node["kernel"]["release"]}"
elsif platform_family?("rhel")
  linux_headers_package = "kernel-devel"
else
  raise "Unsupported platform: #{node["platform"]}"
end


[ qemu_package, linux_headers_package, "vms-libvirt", "vms-mcdist" ].each do |pkg|
  package pkg do
    action :upgrade
    if platform?("ubuntu")
      options "-o Dpkg::Options::='--force-confnew'"
    end
  end
end

unless node["vms"]["sysconfig"]["rados_pool"].nil?
  if node["vms"]["sysconfig"]["vms_memory_url"].nil?
    node["vms"]["sysconfig"]["vms_memory_url"] = "rados://#{node["vms"]["sysconfig"]["rados_pool"]}"
    unless node["vms"]["sysconfig"]["rados_prefix"].nil?
      node["vms"]["sysconfig"]["vms_memory_url"] += "/#{node["vms"]["sysconfig"]["rados_prefix"]}"
    end
  end

  package "vms-rados" do
    action :upgrade
  end
end

unless node["vms"]["sysconfig"]["rbd_pool"].nil?
  if node["vms"]["sysconfig"]["vms_disk_url"].nil?
    node["vms"]["sysconfig"]["vms_disk_url"] = "rbd:#{node["vms"]["sysconfig"]["rbd_pool"]}"
    unless node["vms"]["sysconfig"]["rbd_prefix"].nil?
      node["vms"]["sysconfig"]["vms_disk_url"] += "/#{node["vms"]["sysconfig"]["rbd_prefix"]}"
    end
  end
end

if ["folsom", "essex", "diablo"].include?(node["gridcentric"]["os-version"])
  package "nova-compute-gridcentric" do
    action :upgrade
    if platform?("ubuntu")
      options "-o APT::Install-Recommends=0 -o Dpkg::Options::='--force-confnew'"
    end
  end
else
  package "cobalt-compute" do
    action :upgrade
    if platform?("ubuntu")
      options "-o APT::Install-Recommends=0 -o Dpkg::Options::='--force-confnew'"
    end
  end
end

template "/etc/sysconfig/vms" do
  source "vms.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(node["vms"]["sysconfig"])
end

# Clean up the dummy script we may have created in the workaround
# earlier. It's safe to unconditionally delete the file since the
# broken package is no longer distributed and since we just finished a
# successful install/upgrade, we definitely do not need the script
# anymore.
execute "cleanup dummy start-stop-vmsmd" do
  command "rm -f /usr/sbin/start-stop-vmsmd"
  action :run
end
