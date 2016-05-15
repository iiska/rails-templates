gem_group :development, :test do
  gem 'brakeman'
  gem 'bullet'
  gem 'rspec-rails'
  gem 'simplecov'
  gem 'factory_girl_rails'
  gem 'pry-rails'
  gem 'rubocop', require: false
end

environment <<-RUBY
config.generators do |g|
  g.test_framework = :rspec
end
RUBY

%w(development test).each do |e|
  environment env: e do
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
      - "5000:5000"
    links:
      - redis
      - db
    environment:
      - DOCKERIZED=true
YML

file 'Dockerfile', <<-DOCKER
FROM ruby:2.3
MAINTAINER "#{ask('Dockerfile maintainer? Eg. John Doe <john@example.com>')}"

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev

# Setup Rails application
# =======================
ENV APP_DIR /app
RUN mkdir $APP_DIR
WORKDIR $APP_DIR

ADD Gemfile $APP_DIR/Gemfile
ADD Gemfile.lock $APP_DIR/Gemfile.lock
RUN bundle install

ADD . $APP_DIR

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
DOCKER

after_bundle do
  generate 'rspec:install'

  inject_into_file 'spec/spec_helper.rb',
                   before: 'RSpec.configure do |config|' do
    "require 'simplecov'\nSimpleCov.start 'rails'\n"
  end

  inject_into_file 'spec/spec_helper.rb',
                   after: 'RSpec.configure do |config|' do
    '  config.include FactoryGirl::Syntax::Methods'
  end

  run 'brakeman --rake'

  run 'docker-compose build'
  run 'docker-compose run -e RAILS_ENV=test rake db:create'
end
