#
# Cookbook Name:: cobblerd
# Recipe:: source
#
# Copyright (C) 2015 Bloomberg Finance L.P.
#

if node[:platform_family] == "rhel"
  target_filename = 'cobbler.rpm'
else if node[:platform_family] == "debian"
  target_filename = 'cobbler.deb'
else
  raise "Unsupported OS family: #{node[:platform_family]}"
end

target_filepath = "#{node[:cobbler][:bin_dir]}/#{target_filename}"
source_code_location = "#{Chef::Config[:file_cache_path]}/cobbler"
owner = node[:cobbler][:owner]
group = node[:cobbler][:group]

%w{pyflakes
   pep8
   python-sphinx
   python-cheetah
   python-yaml
   python-nose
   debhelper}.each do |pkg|
  package pkg
end

git source_code_location do
  repository node[:cobbler][:repo][:url]
  revision node[:cobbler][:repo][:branch]
  action :sync
  notifies :run, 'bash[compile cobbler]', :immediately
  not_if { ::File.exist?(target_filepath) }
end

if node[:platform_family] == "rhel"
  bash 'compile cobbler' do
    user owner
    group group
    code %Q{make rpms
            cp cobbler-*.x86_64.rpm #{target_filepath}
    }
    cwd source_code_location
    action :nothing
  end
else if node[:platform_family] == "debian"
  bash 'compile cobbler' do
    user owner
    group group
    code %Q{dpkg-buildpackage -b -us -uc
            rm ../cobbler_*.changes
            cp ../cobbler_*_all.deb #{target_filepath}
    }
    cwd source_code_location
    action :nothing
  end
else
  raise "Unsupported OS family: #{node[:platform_family]}"
end

bash "cleanup" do
   code "rm -rf #{source_code_location}"
   only_if ::File.exist?(source_code_location)
end
