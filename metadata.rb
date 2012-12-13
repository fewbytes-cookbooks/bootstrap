name             "bootstrap"
maintainer       "Fewbytes"
maintainer_email "chef@fewbytes.com"
license          "All rights reserved"
description      "Bootstrap recipes for chef-solo on EC2"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"

depends          "cloudformation"
depends          "ohai"
depends          "chef-client"
depends          "hostsfile"
depends          "build-essential"
