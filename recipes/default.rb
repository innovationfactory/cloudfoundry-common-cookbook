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

interface = node[:cloudfoundry_common][:vlan_interface]
node.automatic_attrs[:ipaddress] = node["network"]["interfaces"][interface]["routes"][0]["src"]

if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef Solo does not support search.")
else
  nats_server_node = search(:node, 'recipes:nats-server')
  unless nats_server_node.empty?
    node[:cloudfoundry_common][:nats_server][:user] = nats_server_node[0][:nats_server][:user]
    node[:cloudfoundry_common][:nats_server][:password] = nats_server_node[0][:nats_server][:password]
    node[:cloudfoundry_common][:nats_server][:host] = nats_server_node[0][:ipaddress]
    node[:cloudfoundry_common][:nats_server][:port] = nats_server_node[0][:nats_server][:port]
  end
end

include_recipe "apt"
include_recipe "cloudfoundry-common::directories"
include_recipe "cloudfoundry-common::ruby_1_9_2"
