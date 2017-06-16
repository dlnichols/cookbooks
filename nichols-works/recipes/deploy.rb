#
# Cookbook Name:: nichols-works
# Recipe:: deploy
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
LOG_TAG = "::NicholsWorks::Deploy "

instance = search(:aws_opsworks_instance, "self:true").first

search(:aws_opsworks_app, "deploy:true").each do |app|
  docker_image "#{app[:environment]['DOCKER_IMAGE']}" do
    tag app[:environment]['DOCKER_TAG'] || "latest"
    action :pull
    not_if { app[:environment]['DOCKER_IMAGE'].nil? }
  end

  docker_container "#{app[:shortname]}" do
    repo app[:environment]['DOCKER_IMAGE']
    tag app[:environment]['DOCKER_TAG'] || "latest"
    host_name app[:domains]&.first&.split(".")&.first
    network_mode node[:nichols_works][:network][:name]
    network_aliases app[:domains].map { |domain| domain.split(".").first }
    port app[:environment]['DOCKER_PORTS']&.split || []
    volumes app[:environment]['DOCKER_VOLUMES']&.split || []
    env app[:environment]&.map { |k, v| "#{k.gsub("___","-")}=#{v}" } || []
    entrypoint app[:environment]['ENTRYPOINT']
    log_driver "awslogs"
    log_opts [ "awslogs-region=#{node[:nichols_works][:zone]}",
               "awslogs-group=#{node[:nichols_works][:log_group]}",
               "awslogs-stream=#{instance[:hostname]}/#{app[:shortname]}" ]
    timeout 30
    retries 3
    action :run
    not_if { app[:environment]['DOCKER_IMAGE'].nil? }
  end

  domains = app[:domains].select { |a| a != app[:shortname] }
  route53_record "#{app[:shortname]}.public.dns.horizon" do
    name "#{domains.first}"
    value "#{instance[:hostname]}.#{node[:nichols_works][:routing][:host]}"
    type "CNAME"
    zone_id node[:nichols_works][:routing][:zone]
    overwrite true
    fail_on_error true
    action :create
    only_if { !domains.empty? && instance[:public_ip] && !instance[:public_ip].empty? }
  end
end

#include_recipe "nichols-works::get_ssl_certificates"

include_recipe "nichols-works::clean"
