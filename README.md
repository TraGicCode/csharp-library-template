# Summary

These Templates used for building and release csharp roslyn analyzers.

# Installing modulesync

## windows

```
choco install ruby -y
choco install msys2 -y
Update-SessionEnvironment
ridk install 2 3
gem install modulesync
msync --help
```



## Important Notes

- Templates MUST have a .erb extension. 
- Static files ( that are not templates ) also must have a .erb extension or they wont get moved to your target github repos.
- Default configuration values for files live in `config_defaults.yml`
- To Override or extend values in `config_defaults.yml` simply add a `.sync.yml` at the root of your module repo
    - To override simply use the same config but ovewrite the value
    - to extend you could, for example, have a set of "required" gems that are added to all Gemfiles, and a set of "optional" gems that a single module might add.
    - you can also add more complicated ruby that like ensures arrays from both files are unique when it combines them or alows you to exclude certain items from the      config_defaults.yml array.
- I think Arrays and hashes get merged together
    - if a key conflicts it's overwritten
    - single vlaues overwrite as well
    - hashes with different keys get merged
    - arrays get merged
- Values are accessed with the @configs hash
- `:globals` allows you to define defaults that are accessed from every file ( Maybe something like library_type )


Documentation from puppetlabs on how to use modulesync
https://github.com/puppetlabs/modulesync_configs

## Example Use Cases

Puppet's pdk-templates utilizes modulesync under the covers ( or something similiar ) and therefore provides some pretty good examples on strategies for handling certain situations.  Below are the documentated tricks that i've seen out in the wild.

NOTE: Remember, this can be applied globally by adding it to config_default.yml or if you only want it to apply to a specific module add is to that modules .sync.yml

## Prevent msync from trying to change/update a file

.sync.yml
```
---
appveyor.yml:
    unmanaged: true
```


## Remove/Delete a file that isn't applicable

.sync.yml
```
---
appveyor.yml
    delete: true
```

## Adding module specific items to .gitignore

.sync.yml
```
.gitignore:
  paths:
    - .puppet-lint.rc
```

.gitignore

```
# Managed by modulesync - DO NOT EDIT
# https://voxpupuli.org/docs/updating-files-managed-with-modulesync/

pkg/
Gemfile.lock
Gemfile.local
vendor/
.vendor/
spec/fixtures/manifests/
spec/fixtures/modules/
.vagrant/
.bundle/
.ruby-version
coverage/
log/
.idea/
.dependencies/
.librarian/
Puppetfile.lock
*.iml
.*.sw?
.yardoc/
Guardfile
<% if ! @configs['paths'].nil? -%>
<% @configs['paths'].each do |path| -%>
<%= path %>
<% end -%>
<% end -%>
```


## Adding to an array of items

.sync.yml
```
---
Gemfile:
  optional:
    ':test':
      - gem: puppet-lint-param-docs
```

config_defaults.yml
```
Gemfile:
  puppet_version: '>= 6.0'
  required:
    ':test':
      - gem: voxpupuli-test
        version: '~> 2.1'
      - gem: coveralls
      - gem: simplecov-console
    ':development':
      - gem: guard-rake
      - gem: overcommit
        version: '>= 0.39.1'
    ':system_tests':
      - gem: puppet_metadata
        version: '~> 0.3.0'
      - gem: voxpupuli-acceptance
    ':release':
      - gem: github_changelog_generator
        version: '>= 1.16.1'
      - gem: puppet-blacksmith
      - gem: voxpupuli-release
      - gem: puppet-strings
        version: '>= 2.2'
```
source ENV['GEM_SOURCE'] || "https://rubygems.org"

<% groups = {} -%>
<% (@configs['required'].keys + ((@configs['optional'] || {}).keys)).uniq.each do |key| -%>
<%   groups[key] = (@configs['required'][key] || []) + ((@configs['optional'] || {})[key] || []) -%>
<% end -%>
<% -%>
<% groups.each do |group, gems| -%>
group <%= group %> do
<% maxlen = gems.map! do |gem| -%>
<%            gem['platforms'].map!{|a| a.to_sym} unless gem['platforms'].nil? -%>
<%            { -%>
<%              'gem'           => gem['gem'], -%>
<%              'version'       => gem['version'], -%>
<%              'platforms'     => gem['platforms'], -%>
<%              'require'       => gem['require'], -%>
<%              'git'           => gem['git'], -%>
<%              'branch'        => gem['branch'], -%>
<%              'ruby-version'  => gem['ruby-version'], -%>
<%              'ruby-operator' => gem['ruby-operator'], -%>
<%              'length'        => gem['gem'].length + (("', '".length if gem['version']) || 0) + gem['version'].to_s.length -%>
<%            } -%>
<%          end.map do |gem| -%>
<%            gem['length'] -%>
<%          end.max -%>
<% gems.each do |gem| -%>
  gem '<%= gem['gem'] %>'<%= ", '#{gem['version']}'" if gem['version'] %>, <%= ' ' * (maxlen - gem['length']) %> :require => false<%= ", :git => '#{gem['git']}'" if gem['git'] %><%= ", :branch => '#{gem['branch']}'" if gem['branch'] %><%= ", :platforms => #{gem['platforms']}" if gem['platforms'] %><%= " if RUBY_VERSION #{gem['ruby-operator']} '#{gem['ruby-version']}'" if (gem['ruby-operator'] && gem['ruby-version']) %>
<% end -%>
end
<% end -%>
gem 'puppetlabs_spec_helper', '>= 2', '< 4', :require => false
gem 'rake', :require => false
gem 'facter', ENV['FACTER_GEM_VERSION'], :require => false, :groups => [:test]

puppetversion = ENV['PUPPET_VERSION'] || '<%= @configs['puppet_version'] %>'
gem 'puppet', puppetversion, :require => false, :groups => [:test]
```


## Adding a here doc

```
Gemfile:
  optional:
    ':acceptance':
      - gem: beaker
      - gem: beaker-rspec
      - gem: beaker-puppet_install_helper
      - gem: beaker-module_install_helper
      - gem: vagrant-wrapper
spec/spec_helper.rb:
  spec_overrides: |-
    # Add coverage report.
    RSpec.configure do |c|
      c.after(:suite) do
        RSpec::Puppet::Coverage.report!
      end
    end
```

# Appending to an array

config_defaults.yml
```
.travis.yml:
    includes:
        - env: CHECK="validate lint check rubocop"
        stage: static
        - env: PUPPET_GEM_VERSION="~> 6.0" CHECK=parallel_spec
        rvm: 2.5.7
        stage: spec
```

.sync.yml
```
.travis.yml:
  includes:
    - env: PUPPET_GEM_VERSION="~> 4.0" CHECK=parallel_spec
      rvm: 2.1.9
```