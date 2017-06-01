#
# Cookbook Name:: nichols-works
# Recipe:: remove_routing
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
LOG_TAG = "::NicholsWorks::RemoveRouting "

instance = search(:aws_opsworks_instance, "self:true").first

route53_record "public.dns.horizon" do
  name "#{instance[:hostname]}.#{node[:nichols_works][:routing][:host]}"
  value instance[:public_ip]
  type "A"
  zone_id node[:nichols_works][:routing][:zone]
  overwrite true
  fail_on_error true
  action :delete
  only_if { instance[:public_ip] && !instance[:public_ip].empty? }
end
