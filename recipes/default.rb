include_recipe "cloudformation"

if node.attribute? 'cloudformation'
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

new_hostname = "#{conf["role"].tr("_", "-")}-#{node["ec2"]["instance_id"]}"
new_fqdn = "#{new_hostname}.#{conf["environment"].tr("_", "-").downcase}.#{domain}"

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
json_attribs = Hash["run_list" => conf["run_list"] || ["role[#{conf["role"]}]"]]

file "/etc/chef/validation.pem" do
  mode "0600"
  content conf["validationCert"]
end
file "/etc/chef/first-boot.json" do
  mode "0644"
  content Chef::JSONCompat.to_json(json_attribs)
end

ruby_block "reload_client_config" do
  block do
    Chef::Config.from_file("#{node["chef_client"]["conf_dir"]}/client.rb")
    Chef::Config[:solo] = false
    Chef::Config[:client_fork] = true
    chef_client = Chef::Client.new(json_attribs)
    Chef::Log.warn "Starting chef-client run"
    chef_client.run
  end
end
