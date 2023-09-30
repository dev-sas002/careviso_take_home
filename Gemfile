source "https://rubygems.org"

ruby file: ".ruby-version"

gem "bootsnap", require: false
gem "dotenv-rails"
gem "jsbundling-rails"
gem "pg", "~> 1.6"
gem "puma", ">= 7.0"
gem "rails", "~> 8.1.0"
gem "sprockets-rails"
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "factory_bot_rails"
  gem "rspec-rails"
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "rails-controller-testing"
  gem "shoulda-matchers"
end
