include_recipe "rbenv"
include_recipe "rbenv::ruby_build"

# Compile ruby with readline support
package "libreadline-dev"
rbenv_ruby node['cloudfoundry_common']['ruby_1_9_2_version']

