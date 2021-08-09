# Summary

Templates to help provide consistency and reduce overhead required for creating and maintaining my open-source csharp projects.

## Installing modulesync

### windows

```
choco install ruby -y
choco install msys2 -y
Update-SessionEnvironment
ridk install 2 3
gem install modulesync
msync --help
```

# Creating a new github repository

1. Navigate to the directory in which you want the git repo to be cloned into
1. Create github repository with basic readme ( NOTE: at least 1 file must exist within the github repository )

```
> cd C:\Source\tragiccode\
> gh repo create NServiceBus.CustomChecks.SqlServer --gitignore VisualStudio --public -y
> cd C:\Source\tragiccode\csharp-library-template
```
1. Update `managed_modules.yml` with the name of the new gitub repository
1. Update the :global: section of the `config_defaults.yml` to contain the new github repository and appropriate library_type ( as of now only nservicebus-custom-check exists )
1. The first time you run modulesync you will probably want to add a .sync.yml to provide customizations/additions specific to the new github repository (Ex: nuget package tags ).  Follow the workflow
   below for adding a .sync.yml and changing/adding values to it.


# Workflow for adding .sync.yml and/or adding values to it

1. Get the projects to get cloned and sync to run
  - msync update --noop
1. Add and/or update .sync.yml with new changes
1. Run msync offline to prevent loosing changes
  - msync update --offline
1. verify results
1. run ./scripts/commit-and-push-sync-file-changes.ps1
  a. Loop through each module and make a commit to the modulesync branch ( which msync is already switched to ) to indicate you updated/added the file manually
  b. Now run msync to push the branch and changes and create the pr 
    - msync update --pr

## Example Use Cases


## Prevent msync from trying to change/update a file

Sometimes you might not want msync to manage a file or set of files at all.  In this case, you can simply inform msync the file should be `unmanaged`

Common Examples of when you would do this:
- If you have a file that has to many deviations from the current templates and you would like to no longer manage it simply add the following to the repo's .sync.yml.
- If you want to utilize msync for initial creationg of github files but after the initial sync never change and be allowed to deviate to reduce github repo setup overhead

.sync.yml
```
---
appveyor.yml:
    unmanaged: true
```


## Remove/Delete a file that isn't applicable

If a file is not applicable for your library then you can update the .sync.yml to ensure the file will be deleted and not be commited as part of the repository.

.sync.yml
```
---
appveyor.yml
    delete: true
```

## Adding module specific items to .gitignore

Sometimes you want to provide a customization point for modules to apply any "extra" stuff they might need to a file.  The below is a great example of how to do this.

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

Here is another example of where there is no sane default that can be applied but the code is written in a way that it wont blow up

```
<%- (@configs['environment'] || []).each do |key, value| -%>
  <%= key %>: <%= value %>
<%- end -%>
```


# Configuration that is has no default, but is optional and is defined in the modules .sync.yml

https://github.com/puppetlabs/pdk-templates/blob/main/moduleroot/spec/default_facts.yml.erb
Shows how to have something optional that has no sane default in default_config.yml

## Explicitly excluding certain defaults

Below shows an example on how to utilize defaults, add .sync.yml extras, AND exclude certain defaults is the module needs to.

```
<%- (((@configs['matrix']) + (@configs['matrix_extras'] || [])) - (@configs['remove_includes'] || [])).each do |matrix| -%>
```

## Combining default configurations + .sync.yml configurations

Sometimes you want to have some defaults that might change in the future along with customizations from a module.  Below is an example on how to merge the configurations together


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


## Adding a here doc string

Below shows an example of adding a multi-line string to a template using here doc style strings

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

# Add helper function as top of function

To help keep the template clean, you can create a helper function at the top of t he file like so. 
```
<%
def requires(item)
  if item.is_a? String
    line = "require '#{item}'"
  elsif item.is_a? Hash
    line = "require '#{item['require']}'" unless item['require'].nil?
    line = "#{line} if #{item['conditional']}" unless item['require'].nil? and item['conditional'].nil?
  end
  line
end
-%>
```


TODO: Investigate extracting this to a file and being able to `require` it into the template that needs to use it


# Add content based on if certain directories/files exist in the repository

```
<%- if Dir[File.join(@metadata[:workdir], 'spec', 'acceptance', '**', '*_spec.rb')].any? -%>

  acceptance:
    needs: setup_matrix
    runs-on: ubuntu-latest
    env:
      BUNDLE_WITHOUT: development:test:release
    strategy:
      fail-fast: false
      matrix:
        setfile: ${{fromJson(needs.setup_matrix.outputs.beaker_setfiles)}}
        puppet: ${{fromJson(needs.setup_matrix.outputs.puppet_major_versions)}}
        <%- @configs['beaker_fact_matrix'].each do |option, values| -%>
        <%= option %>:
        <%- values.each do |value| -%>
          - "<%= value %>"
        <%- end -%>
        <%- end -%>
        <%- if @configs['excludes'].any? -%>
        exclude:
        <%- @configs['excludes'].each do |exclude| -%>
        <%- exclude.each do |key, value| -%>
          <%= key == exclude.first.first ? '-' : ' ' %> <%= key %>: "<%= value %>"
        <%- end -%>
        <%- end -%>
        <%- end -%>
    <%-
      name = ['${{ matrix.puppet.name }}', '${{ matrix.setfile.name }}']
      @configs['beaker_fact_matrix'].each_key do |option|
        name << "#{option.tr('_', ' ').capitalize} ${{ matrix.#{option} }}"
      end
    -%>
    name: <%= name.join(' - ') %>
    steps:
      - uses: actions/checkout@v2
      - name: Setup ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.0'
          bundler-cache: true
      - name: Run tests
        run: bundle exec rake beaker
        env:
          BEAKER_PUPPET_COLLECTION: ${{ matrix.puppet.collection }}
          BEAKER_setfile: ${{ matrix.setfile.value }}
          <%- @configs['beaker_fact_matrix'].keys.each do |fact| -%>
          BEAKER_FACTER_<%= fact.upcase %>: ${{ matrix.<%= fact %> }}
          <%- end -%>
<%- end -%>
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

