gsub_file 'Gemfile', "# gem 'therubyracer', platforms: :ruby",
          "gem 'therubyracer', platforms: :ruby"
gem_group :development, :test do
  gem 'brakeman'
  gem 'bullet'
  gem 'rspec-rails'
  gem 'simplecov'
  gem 'factory_girl_rails'
  gem 'pry-rails'
  gem 'rubocop', require: false
end

# Replace jQuery with Vanilla UJS
gsub_file 'Gemfile', /# Use jquery.*\ngem 'jquery-rails'/,
          "# https://github.com/hauleth/vanilla-ujs\ngem 'vanilla-ujs'"
gsub_file 'app/assets/javascripts/application.js',
          %r{//=\s+require jquery\n//=\s+require jquery_ujs},
          '//= require vanilla-ujs'

inject_into_file 'config/database.yml',
                 after: "default: &default\n" do
  <<-YAML
  host: db
  username: #{app_name}
  password: password
  YAML
end

environment <<-RUBY
config.generators do |g|
    g.test_framework = :rspec
  end
RUBY

%w[development test].each do |e|
  environment(nil, env: e) do
    <<-RUBY
config.after_initialize do
    Bullet.enable = true
    Bullet.raise = true
    Bullet.rails_logger = true
  end
    RUBY
  end
end

file 'docker-compose.yml', <<-YML
version: '2'
volumes:
  pg_data: {}
services:
  redis:
    image: redis

  db:
    image: postgres:9.5
    ports:
      - "5432:5432"
    volumes:
      - pg_data:/var/lib/postgresql/data/pgdata
    environment:
      POSTGRES_USER: #{app_name}
      POSTGRES_PASSWORD: password
      POSTGRES_DB: #{app_name}_development
      PGDATA: /var/lib/postgresql/data/pgdata

  app:
    build:
      context: .
    command: bundle exec rails s -b 0.0.0.0
    volumes:
      - .:/app:z
    ports:
      - "3000:3000"
    links:
      - redis
      - db
    environment:
      - DOCKERIZED=true
YML

file 'Dockerfile', <<-DOCKER
FROM ruby:2.3
MAINTAINER "#{ask('Dockerfile maintainer? Eg. John Doe <john@example.com>')}"

RUN apt-get update -qq && \
  apt-get install -y build-essential libpq-dev libssl-dev

RUN echo "gem: --no-document" >> /etc/gemrc

# Setup Rails application
# =======================
ENV APP_DIR /app
RUN mkdir $APP_DIR
WORKDIR $APP_DIR

ADD Gemfile $APP_DIR/Gemfile
ADD Gemfile.lock $APP_DIR/Gemfile.lock
RUN bundle install

ADD . $APP_DIR

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
DOCKER

build_docker = yes?('Build Docker images?')

after_bundle do
  generate 'rspec:install'

  file 'spec/support/factory_girl.rb', <<-FACTORY_GIRL
RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end
  FACTORY_GIRL

  inject_into_file 'spec/spec_helper.rb',
                   before: 'RSpec.configure do |config|' do
    "require 'simplecov'\nSimpleCov.start 'rails'\n"
  end

  inject_into_file 'spec/rails_helper.rb',
                   after: /# Add additional requires.*/ do
    "require 'support/factory_girl'\n"
  end

  run 'brakeman --rake' unless File.exist? 'lib/tasks/brakeman.rake'

  if build_docker
    run 'docker-compose build'
    run 'docker-compose run -e RAILS_ENV=test app rake db:create'
  end
end
