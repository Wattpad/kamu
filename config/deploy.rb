require "aws-sdk"

set :application, "kamu"
set :copy_exclude, ['.git']
set :deploy_to, "/var/kamu"
set :deploy_via, :remote_cache
set :repository,  "git@github.com:Wattpad/kamu.git"
set :scm, :git
set :user, "root"
set :keep_releases, 5
set :aws_access_key_id, ENV['AWS_ACCESS_KEY_ID']
set :aws_secret_access_key, ENV['AWS_SECRET_ACCESS_KEY']


desc "Function to get ec2 servers for a given role and tier"
def get_ec2_servers(cap_role, tier, role, main=nil, ec2_region='us-east-1')
  instances = get_ec2_running(ec2_region).with_tag('role', role).with_tag('tier', tier)
  puts "Looking for #{cap_role} servers..."
  if (main != nil) then
    instances = instances.tagged('main')
  end
  puts "Found #{instances.count}"
  instances.each do |instance|
    # server instance.private_dns_name, cap_role
    server instance.public_dns_name, cap_role
  end
end

desc "Function to get all EC2 running hosts"
def get_ec2_running(ec2_region='us-east-1')
  AWS.config(
    :access_key_id => aws_access_key_id,
    :secret_access_key => aws_secret_access_key,
  )
  AWS.start_memoizing
  if @ec2_running_instances.nil?
    puts "Looking for running servers in #{ec2_region}..."
    @ec2_running_instances = AWS::EC2.new(:region => ec2_region).instances.filter('instance-state-name', 'running')
    puts "Found #{@ec2_running_instances.count}"
  end
  return @ec2_running_instances
end

get_ec2_servers(:kamu, 'production', 'kamu')

task :set_git_ssh do
  default_environment[:GIT_SSH] = '/root/ssh-git.sh'
end

desc "Performs a deploy remotely from the jump server"
task :remote_deploy, :hosts => "wattpad.com" do
  set :user, "ubuntu"
  run "ssh-agent bash -c 'ssh-add /home/ubuntu/.ssh/kamu; cd /home/ubuntu/kamu; git checkout .; git clean -f; git pull origin master; cap deploy'"
end

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
    run "docker run --env-file=/var/#{container_prefix}/shared/env.list --tty --detach --restart=always --name=#{container_name} #{image_name}"
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

before "deploy", "set_git_ssh"
after "deploy:update_code", "docker:update"
after "deploy:update", "docker:switch_over"
after "deploy", "deploy:cleanup", 'docker:tail_logs'
