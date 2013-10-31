include_recipe "cloudformation"

if node.attribute? 'cloudformation'
  if node["cloudformation"]["metadata"]["chef"]["serverURL"]
    # Chef client mode
    node.default["chef_client"]["config"]["chef_server_url"] = node["cloudformation"]["metadata"]["chef"]["serverURL"]
    node.default["chef_client"]["config"]["environment"] = node["cloudformation"]["metadata"]["chef"]["environment"]
    domain = node["cloudformation"]["metadata"]["generic"]["domain"]
  end
  conf = node["cloudformation"]["metadata"]["chef"]
  # normal instance bootstrap
elsif node["ec2"].attribute? "tags" and node["ec2"]["tags"]["chef::serverURL"]
  node.default["chef_client"]["config"]["serverURL"] = node["ec2"]["tags"]["chef::serverURL"]
  node.default["chef_client"]["config"]["environment"] = node["ec2"]["tags"]["chef::environment"]
  domain = node["ec2"]["tags"]["generic::domain"]
else
  raise RuntimeError, "Can't find boostrap data"
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
  comment 'Added by bootstrap recipe'
end
hostsfile_entry node["ec2"]["local_ipv4"] do
  hostname new_fqdn
  aliases [new_hostname]
  comment 'Added by bootstrap recipe'
end

include_recipe "chef-client::config"
json_attribs = Hash["run_list" => conf["run_list"] || ["role[#{conf["role"]}]"]]

file "/etc/chef/validation.pem" do
  mode "0600"
  content conf["validationCert"]
  action :create
end
file "/etc/chef/first-boot.json" do
  mode "0644"
  content Chef::JSONCompat.to_json(json_attribs)
  action :create
end

ruby_block "Run chef-client" do
  block do
    Chef::Config.from_file("#{node["chef_client"]["conf_dir"]}/client.rb")
    Chef::Config[:file_cache_path] = node["chef_client"]["cache_path"]
    Chef::Config[:file_backup_path] = node["chef_client"]["backup_path"]
    Chef::Config[:solo] = false
    Chef::Config[:client_fork] = true
    Chef::Config[:node_name] = new_fqdn
    # chef-solo uses the same lockfile as chef-client: `file_cache_path/chef-client-running.pid
    # change the lockfile of the inner chef-client run to avoid hanging
    Chef::Config[:lockfile] = "/tmp/chef-client-first-run.pid"
    chef_client = Chef::Client.new(json_attribs)
    Chef::Log.warn "Starting chef-client run"
    chef_client.run
  end
end
