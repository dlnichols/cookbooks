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
LOG_TAG = "::NicholsWorks::Deploy:: "

instance = search(:aws_opsworks_instance, "self:true").first

search(:aws_opsworks_app, "deploy:true").each do |app|
  app_key = app[:app_source][:url].sub(/.*?\/nw-deployment\//, "")
  app_file = app_key.match(/.*\/(.*)/)[1]
  app_folder = app_file.sub(".tar.gz", "")

  cloud_aws_s3_file "/var/app/#{app_file}" do
    bucket "nw-deployment"
    key app_key
    owner "root"
    group "root"
    mode "0644"
  end

  tar_extract "/var/app/#{app_file}" do
    target_dir "/var/app/#{app_folder}"
    creates "/var/app/#{app_folder}/#{node[:nw_name]}.jar"
  end

  link "/var/app/#{node[:nw_name]}-current" do
    to "/var/app/#{app_folder}"
  end

  docker_container "#{app[:shortname]}" do
    container_name "#{app[:shortname]}"
    kill_after 60
    action :stop
  end

  docker_container "#{app[:shortname]}" do
    repo "#{node[:nw_app_types][app[:shortname]]}"
    container_name "#{app[:shortname]}"
    port "#{node[:nw_ports][app[:shortname]]}"
    volumes [ "/var/app:/var/app" ]
    entrypoint [ "java",
                 "-Djava.security.egd=file:/dev/./urandom",
                 "-jar",
                 "/var/app/#{node[:nw_name]}-current/#{node[:nw_name]}.jar" ]
  end
end
