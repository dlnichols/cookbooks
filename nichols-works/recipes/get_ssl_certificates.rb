#
# Cookbook Name:: nichols-works
# Recipe:: get_ssl_certificates
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
LOG_TAG = "::NicholsWorks::GetSSLCertificates "

instance = search(:aws_opsworks_instance, "self:true").first
apps = search(:aws_opsworks_app, "deploy:true")

docker_image :nginx do
  tag node[:nichols_works][:nginx][:version]
  action :pull
  only_if { !apps.empty? }
end

docker_container "nginx-static" do
  repo "nginx"
  tag node[:nichols_works][:nginx][:version]
  port "80:80/tcp"
  log_driver "awslogs"
  log_opts [ "awslogs-region=#{node[:nichols_works][:zone]}",
             "awslogs-group=#{node[:nichols_works][:log_group]}",
             "awslogs-stream=#{instance[:hostname]}/nginx-static" ]
  volumes [ "#{node[:nichols_works][:paths][:static_root]}:/usr/share/nginx/html:ro" ]
  action :run
  only_if { ::File.exists? "/var/www" && !apps.empty? }
end

include_recipe "acme"

apps.each do |app|
  domains = app[:domains].select { |a| a != app[:shortname] }
  acme_certificate domains.first do
    owner     "root"
    group     "root"
    key       "#{node[:nichols_works][:paths][:certs]}/#{app[:shortname]}.key"
    fullchain "#{node[:nichols_works][:paths][:certs]}/#{app[:shortname]}.pem"
    wwwroot   node[:nichols_works][:paths][:static_root]
    notifies  :restart, 'docker_container[nginx-proxy]', :delayed
    only_if   { !domains.first.nil? }
  end
end

docker_container "nginx-static" do
  kill_after 60
  action :stop
  only_if { !apps.empty? }
end
