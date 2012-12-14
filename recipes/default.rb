include_recipe "cloudformation"
require 'json'

if node['cloudformation'] 
  if node["cloudformation"]["metadata"]["chef"]["serverURL"]
    # Chef client mode
    node.default["chef_client"]["server_url"] = node["cloudformation"]["metadata"]["chef"]["serverURL"]
    node.default["chef_client"]["environment"] = node["cloudformation"]["metadata"]["chef"]["environment"]
    domain = node["cloudformation"]["metadata"]["generic"]["domain"]
  else
    # not implemented yet

  end
  conf = node["cloudformation"]["metadata"]["chef"]
  # normal instance bootstrap
end

new_hostname = "#{conf["role"]}-#{node["ec2"]["instance_id"]}"
new_fqdn = "#{conf["environment"].tr("_", "-").downcase}.#{domain}"

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
hostsfile_entry node["ec2"]["local_ipv4"] do
  hostname new_fqdn
  aliases [new_hostname]
  comment 'Append by bootstrap recipe'
end

include_recipe "chef-client::config"

file "/etc/chef/validation.pem" do
  mode "0600"
  content conf["validationCert"]
end
file "/etc/chef/first-boot.json" do
  mode "0644"
  content Hash.new("run_list" => ["role[#{conf["role"]}]"]).to_json
end
execute "chef-client -j /etc/chef/first-boot.json" 
