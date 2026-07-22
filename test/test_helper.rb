ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    self.fixture_paths = [Rails.root.join("test/fixtures")]
    parallelize(workers: 1, with: :threads)
    fixtures :all
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_paths = ["test/fixtures"]
end