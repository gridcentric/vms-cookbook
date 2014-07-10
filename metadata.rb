name             "vms"
maintainer       "Gridcentric Inc."
maintainer_email "support@gridcentric.com"
license          "All rights reserved"
description      "Installs/Configures vms"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.3.0"

%w{ ubuntu centos }.each do |os|
  supports os
end

depends "apt"
depends "yum", ">= 3.0.0"
