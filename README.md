My [application templates][rails-templates-guide] for Ruby on Rails.

[rails-templates-guide]: http://guides.rubyonrails.org/rails_application_templates.html

1. Copy railsrc to your $HOME as .railsrc

    cp railsrc $HOME/.railsrc

2. Running `` rails new APP_NAME `` will now get default args from .railsrc and
   uses template `` https://github.com/iiska/rails-templates/raw/master/basic.rb ``

Template includes following gems:

- [bullet][bullet-site]: N+1 query detector
- [brakeman][brakeman-site]: Brakeman security scanner
- [pry][pry-site]: Powerful IRB shell replacement
- [rspec][rspec-site]: For testing instead of TestUnit
- [simplecov][simplecov-site]: Test coverage reporting
- [factory_girl_rails][factory-girl-site]: Factories instead of fixtures
- [rubocop][rubocop-site]: Static code analysis and style enforcer

[bullet-site]: https://github.com/flyerhzm/bullet
[brakeman-site]: http://brakemanscanner.org/
[rspec-site]: http://rspec.info/
[simplecov-site]: https://github.com/colszowka/simplecov
[factory-girl-site]: https://github.com/thoughtbot/factory_girl_rails
[pry-site]: http://pryrepl.org/
[rubocop-site]: https://github.com/bbatsov/rubocop

It also creates [Docker][docker] configuration for running development environment and
build default Docker Compose environment for it creating development and test
databases into dockerized PostgreSQL server.

[docker]: http://docker.io
