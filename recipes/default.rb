include_recipe "cloudformation"
require 'json'

if node['cloudformation'] 
  if node["cloudformation"]["metadata"]["chef"]["serverURL"]
    # Chef client mode
    node.default["chef_client"]["server_url"] = node["cloudformation"]["metadata"]["chef"]["serverURL"]
    environment = node.default["chef_client"]["environment"] = node["cloudformation"]["chef"]["metadata"]["environment"]
    domain = node["cloudformation"]["chef"]["metadata"]["generic"]["domain"]
  else
    # not implemented yet

  end
  conf = node["cloudformation"]["chef"]["metadata"]["chef"]
  # normal instance bootstrap
end

new_hostname = "#{role}-#{node["ec2"]["instance_id"]}"
new_fqdn = "#{environment.tr("_", "-").downcase}.#{domain}"

file "/etc/hostname" do
  mode "0644"
  content new_hostname
end
execute "hostname #{new_hostname}"

hostsfile_entry node["ec2"]["public_ipv4"] do
  hostname new_fqdn
  aliases [new_hostname]
  comment 'Append by bootstrap recipe'
end
hostsfile_entry node["ec2"]["private_ipv4"] do
  hostname new_fqdn
  aliases [new_hostname]
  comment 'Append by bootstrap recipe'
end

include_recipe "chef-client"
file "/etc/chef/first-boot.json" do
  mode "0644"
  content Hash.new("run_list" => ["role[#{conf["role"]}]"]).to_json
end
execute "chef-client -j /etc/chef/first-boot.json" 
