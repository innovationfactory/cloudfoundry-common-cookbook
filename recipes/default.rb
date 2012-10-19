#
# Cookbook Name:: cloudfoundry-common
# Recipe:: default
#
# Copyright 2012, Trotter Cashion
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

interface = node['cloudfoundry_common']['vlan_interface']
node.automatic_attrs['ipaddress'] = node["network"]["interfaces"][interface]["routes"][0]["src"]

if node['recipes'].include?("nats-server") # nats-server is on same node, therefore it has the same IP address: search not necessary.
  node['cloudfoundry_common']['nats_server']['host'] = node['ipaddress']

  # randomly generate nats password
  ::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
  node.set_unless['cloudfoundry_common']['nats_server']['password'] = secure_password
  node.save unless Chef::Config['solo']
else
  if Chef::Config['solo']
    Chef::Log.warn("This recipe uses search. Chef Solo does not support search.")
  else
    nats_server_node = search(:node, 'recipes:nats-server')
    if nats_server_node.empty?
      Chef::Log.error("No node with nats-server recipe found.")
    else
      node['cloudfoundry_common']['nats_server']['host'] = nats_server_node[0]['ipaddress']
    end
  end
end

include_recipe "apt"
include_recipe "cloudfoundry-common::directories"
include_recipe "cloudfoundry-common::ruby_1_9_2"
