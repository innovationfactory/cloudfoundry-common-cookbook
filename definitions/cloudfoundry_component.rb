define :cloudfoundry_component do
  include_recipe "logrotate"
  include_recipe "cloudfoundry-common"

  component_name = params[:component_name] || "cloudfoundry-#{params[:name]}"

  name         = params[:name]
  ruby_path    = File.join(rbenv_root, "versions", node['cloudfoundry_common']['ruby_1_9_2_version'], "bin")
  config_file  = params[:config_file] || File.join(node['cloudfoundry_common']['config_dir'], "#{name}.yml")
  bin_file     = params[:bin_file] || File.join(node['cloudfoundry_common']['vcap']['install_path'], name, "bin", name)
  install_path = params[:install_path] || File.join(node['cloudfoundry_common']['vcap']['install_path'], name)
  pid_file     = params[:pid_file] || File.join(node["cloudfoundry_#{name}"]['pid_file'])
  log_file     = params[:log_file] || File.join(node["cloudfoundry_#{name}"]['log_file'])
  binary       = params[:binary]   || "#{File.join(ruby_path, "ruby")} #{bin_file}"
  env_vars     = params[:env_vars] || []

  if %w(cloud_controller dea router stager).include? name
    git File.join(node['cloudfoundry_common']['vcap']['install_path'], name) do
      repository        node['cloudfoundry_common'][name]['repo']
      reference         node['cloudfoundry_common'][name]['reference']
      user              node['cloudfoundry_common']['user']
      enable_submodules true
      action :sync
    end
  end

  rbenv_gem "bundler" do
    ruby_version node['cloudfoundry_common']['ruby_1_9_2_version']
  end

  bash "install #{component_name} gems" do
    user node['cloudfoundry_common']['user']
    cwd  install_path
    code "#{File.join(ruby_path, "bundle")} install --without=test"
    only_if { File.exist?(install_path) }
  end

  template config_file do
    source   "#{name}-config.yml.erb"
    owner    node['cloudfoundry_common']['user']
    mode     "0644"
    notifies :restart, "service[#{component_name}]"
  end

  template "/etc/init/#{component_name}.conf" do
    cookbook "cloudfoundry-common"
    source   "upstart.conf.erb"
    variables(
      :component_name => component_name,
      :path        => ruby_path,
      :binary      => binary,
      :config_file => config_file,
      :env_vars    => env_vars
    )
    notifies :restart, "service[#{component_name}]"
  end

  link "/etc/init.d/#{component_name}" do
    to "/lib/init/upstart-job"
  end

  service component_name do
    supports :status => true, :restart => true
    action [:enable, :start]
  end

  logrotate_app component_name do
    cookbook "logrotate"
    path log_file
    frequency daily
    rotate 30
    create "644 root root"
  end
end
