#
# Cookbook Name:: vms
# Library:: helpers
#
# Copyright 2013, Gridcentric Inc.
#
# Some common utility functions.
#

module Gridcentric
  module Repositories
      # pversion is node["platform_version"]
      def self.translate_distro_to_repo_type(distro, pversion, component, osver)
        case distro
        when "centos"
          return "centos"
        when "fedora"
          return "rpm"
        when "ubuntu"
          if component == "vms"
            if pversion == "14.04"
              return "trusty"
            elsif pversion == "13.04"
              return "raring"
            elsif not ["folsom", "essex", "diablo"].include?(osver)
              return "uca/" + osver
            else
              return "ubuntu"
            end
          else
            return "ubuntu"
          end
        when "debian"
          return "deb"
        else
          raise "Unknown distro '#{distro}'"
        end
      end
  end
end
