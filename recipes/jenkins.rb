home = node['jenkins']['master']['home']

include_recipe 'apt'

include_recipe 'java::default'
include_recipe 'jenkins::master'
include_recipe 'u2i-jenkins::_plugins'

## Credentials

keys = Chef::EncryptedDataBagItem.load('keys', 'jenkins')

keys['credentials'].each do |name, values|
  jenkins_private_key_credentials name do
    id values['id'] if values.has_key?('id')
    description values['description'] if values.has_key?('description')
    private_key values['private_key']
  end
end

## Configs
configs = %w(
  .gitconfig
  config.xml
  hudson.plugins.git.GitSCM.xml
  hudson.tasks.Shell.xml
  hudson.plugins.git.GitTool.xml
  hudson.tasks.Mailer.xml
  jenkins.model.JenkinsLocationConfiguration.xml
  hudson.plugins.emailext.ExtendedEmailPublisher.xml
)

configs.each do |config|
  template File.join(home, config) do
    source "jenkins/#{config}.erb"
    owner 'jenkins'
    group 'jenkins'
  end
end

github_config = File.join(home, 'com.cloudbees.jenkins.GitHubPushTrigger.xml')
ghprb_config = File.join(home, 'org.jenkinsci.plugins.ghprb.GhprbTrigger.xml')

template ghprb_config do
  source 'jenkins/org.jenkinsci.plugins.ghprb.GhprbTrigger.xml.erb'
  owner 'jenkins'
  group 'jenkins'
  variables access_token: keys['GhprbTrigger']['accessToken'], admins: keys['GhprbTrigger']['admins'].join(', ')
end

template github_config do
  source 'jenkins/com.cloudbees.jenkins.GitHubPushTrigger.xml.erb'
  owner 'jenkins'
  group 'jenkins'
  variables access_token: keys['GitHubPushTrigger']['accessToken'], admins: keys['GitHubPushTrigger']['admins'].join(', ')
end
