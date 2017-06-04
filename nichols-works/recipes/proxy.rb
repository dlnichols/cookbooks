#
# Cookbook Name:: nichols-works
# Recipe:: proxy
#
# The MIT License (MIT)
#
# Copyright (c) 2016 Daniel Nichols
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
LOG_TAG = "::NicholsWorks::Proxy "

include_recipe "nichols-works::get_ssl_certificates"

instance = search(:aws_opsworks_instance, "self:true").first

apps = search(:aws_opsworks_app).select { |app| !!app[:domains]&.first }
template "#{node[:nichols_works][:paths][:config]}/nginx.conf" do
  source "nginx_conf.erb"
  owner "root"
  group "root"
  mode "0755"
  helper(:apps) { apps }
  action :create
end

docker_image :nginx do
  tag node[:nichols_works][:nginx][:version]
  action :pull
end

docker_container "nginx-proxy" do
  repo "nginx"
  tag node[:nichols_works][:nginx][:version]
  host_name "proxy"
  network_mode node[:nichols_works][:network][:name]
  port "443:443/tcp"
  log_driver "awslogs"
  log_opts [ "awslogs-region=#{node[:nichols_works][:zone]}",
             "awslogs-group=#{node[:nichols_works][:log_group]}",
             "awslogs-stream=#{instance[:hostname]}/nginx-proxy" ]
  volumes [ "#{node[:nichols_works][:paths][:certs]}:/etc/nginx/certs:ro",
            "#{node[:nichols_works][:paths][:config]}/nginx.conf:/etc/nginx/nginx.conf:ro" ]
  action :run
end
