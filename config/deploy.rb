set :application, "kamu"
set :copy_exclude, ['.git']
set :deploy_to, "/var/kamu"
set :deploy_via, :remote_cache
set :repository,  "git@github.com:Wattpad/kamu.git"
set :scm, :git
set :user, "root"
set :keep_releases, 5

ssh_options[:keys] = "~/.ssh/wattpad-production.pem"

role :kamu, "ec2-54-234-54-212.compute-1.amazonaws.com"  # kamu-production-1

default_environment[:GIT_SSH] = '/root/ssh-git.sh'

namespace :docker do

  def container_prefix
    "kamu"
  end

  def container_name
    "#{container_prefix}_#{release_name}"
  end

  def image_name
    "kamu:#{real_revision}"
  end

  task :build_image do
    run "cd #{current_release} && docker build -t #{image_name} ."
  end

  task :run_container do
    run "docker run --env-file=/var/#{container_prefix}/shared/env.list --tty --detach --name=#{container_name} #{image_name}"
  end

  task :route_traffic do
    run <<-CMD
      CONTAINER_IP=$(docker inspect --format='{{.NetworkSettings.IPAddress}}' #{container_name});
      export CONTAINER_HOST=$CONTAINER_IP:8081;

      HTTP_CHECK_ENDPOINT=http://$CONTAINER_HOST;
      echo "Checking container HTTP endpoint: $HTTP_CHECK_ENDPOINT";
      (wget -q --spider --waitretry=4s --retry-connrefused $HTTP_CHECK_ENDPOINT || exit 1);

      echo "Updating nginx config...";
      envtpl < #{current_release}/config/nginx_kamu.conf.tpl > /etc/nginx/sites-enabled/kamu.conf &&
      service nginx reload
    CMD
  end

  task :stop_and_remove_old_containers do
    run <<-CMD
      containers_to_stop=$(docker ps -q --filter='name=#{container_prefix}_' --filter='status=running' | tail -n +2);
      if [ -n "$containers_to_stop" ]; then
        docker stop $containers_to_stop;
      fi;
      containers_to_remove=$(docker ps -q --filter='name=#{container_prefix}_' --filter='status=running' | tail -n +#{ keep_releases + 1});
      if [ -n "$containers_to_remove" ]; then
        docker rm -v $containers_to_remove;
      fi;
    CMD
  end

  task :update do
    on_rollback do
      run <<-CMD
        container_name=#{container_name};
        if docker inspect $container_name &> /dev/null; then
          echo "Removing container: $container_name";
          docker rm -fv $container_name;
        fi;
      CMD
    end
    build_image
    run_container
  end

  task :switch_over do
    route_traffic
    stop_and_remove_old_containers
  end

  desc "Tail production log files"
  task :tail_logs, :on_error => :continue do
    begin
      run "docker logs -f -t --tail=0 $(docker ps --filter=name=#{container_prefix}_ --filter=status=running  -n 1 -q)" do |channel, stream, data|
      puts "#{channel[:host]}: #{data}"
      break if stream == :err
    end
    rescue Exception => error
      puts "Quitting tail and continuing..."
    end
  end

end

after "deploy:update_code", "docker:update"
after "deploy:update", "docker:switch_over"
after "deploy", "deploy:cleanup", 'docker:tail_logs'
