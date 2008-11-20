set :application, "toycity.ie"
set :repository,  "git@github.com:BDQ/toycity.git"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/data/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion
set :scm, "git"
default_run_options[:pty] = true
set :scm_passphrase, ""  
set :user, "deploy"
set :runner, "deploy"

role :app, "10.1.0.29"
role :web, "10.1.0.29"
role :db,  "10.1.0.29", :primary => true

#############################################################
#	Passenger
#############################################################

namespace :passenger do
  desc "Restart Application"
  task :restart do
    run "touch #{current_path}/tmp/restart.txt"
  end
end

after :deploy, "passenger:restart"