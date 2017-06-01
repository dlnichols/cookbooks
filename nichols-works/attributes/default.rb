default[:nichols_works][:paths][:config] = "/srv/proxy/config"
default[:nichols_works][:paths][:certs] = "/srv/proxy/certs"
default[:nichols_works][:paths][:static_root] = "/srv/proxy/www"

default[:nichols_works][:zone] = "us-east-1"
default[:nichols_works][:log_group] = "NicholsWorks"

default[:nichols_works][:docker][:version] = "1.13.1"
default[:nichols_works][:nginx][:version] = "1.13.1-alpine-perl"

default[:nichols_works][:routing][:zone] = "Z3NZBRGVYFDVAY"
default[:nichols_works][:routing][:host] = "nichols.works"

default[:nichols_works][:network][:name] = "nichols.works"
default[:nichols_works][:network][:subnet] = "192.168.88.0/24"
default[:nichols_works][:network][:gateway] = "192.168.88.1"
