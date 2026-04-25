ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

# Minitest 6 removed Object#stub; re-add it for compatibility
module MinitestStubCompat
  def stub(method_name, val_or_callable, *_block_args, **_kw, &block)
    original = method(method_name)
    singleton_class.define_method(method_name) do |*args, **kwargs|
      val_or_callable.respond_to?(:call) ? val_or_callable.call(*args, **kwargs) : val_or_callable
    end
    block.call
  ensure
    singleton_class.define_method(method_name, original)
  end
end
Object.include(MinitestStubCompat)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
