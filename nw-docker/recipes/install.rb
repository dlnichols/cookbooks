#
# Cookbook Name:: nw-docker
# Recipe:: install
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
LOG_TAG = "::NicholsWorks::Install:: "

Chef::Log.info LOG_TAG + "Adding Docker APT repo"
include_recipe "chef-apt-docker"

Chef::Log.info LOG_TAG + "Ensuring cli tools are installed"
include_recipe "cloudcli"

Chef::Log.info LOG_TAG + "Installing and Starting Docker Service"
docker_service :default do
  action [ :create, :start ]
  install_method "package"
  service_manager "systemd"
  version "1.11.2"
  package_options %q|--force-yes -o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-all'|
end

Chef::Log.info LOG_TAG + "Creating app directories"
[ "/var/app", "/var/app/#{node[:nw_name]}", "/var/log/#{node[:nw_name]}", "/var/app/postgres" ].each do |path|
  directory path do
    owner "root"
    group "root"
    mode "0755"
    action :create
  end
end

file "/var/app/postgres/media-db.sql" do
  owner "root"
  group "root"
  mode "0755"
  content <<-eocontent
    CREATE USER "nw-media" WITH "ShamefulMermaidBrassiere42D";
    CREATE DATABASE "nw-media";
    GRANT ALL PRIVILEGES ON DATABASE "nw-media" TO "nw-media";
    \connect "nw-media";
    CREATE SCHEMA liquibase;
  eocontent
end

file "/var/app/postgres/Dockerfile" do
  owner "root"
  group "root"
  mode "0755"
  content <<-eocontent
    FROM postgres:9.5
    ADD [ "media-db.sql", "/docker-entrypoint-initdb.d/media-db.sql" ]
  eocontent
end

docker_image "media-db" do
  tag "0.1.0"
  source "/var/app/postgres"
  action :build
end

docker_network "media-net" do
  subnet "192.168.0.0/24"
  gateway "192.168.0.1"
  action :create
end

docker_container "media-db" do
  repo "media-db"
  tag "0.1.0"
  container_name "media-db"
  host_name "media-db"
  domain_name "nichols.works"
  network_mode "media-net"
  port "5432:5432"
  env [ "POSTGRES_PASSWORD=unsafePassword42" ]
  action :run_if_missing
end
