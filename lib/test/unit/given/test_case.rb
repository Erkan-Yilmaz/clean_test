require 'test/unit'
require 'test/unit/given/simple'
require 'test/unit/given/test_that'

module Test
  module Unit
    module Given
      # Public: A Base class brings in both the Simple Given/Then/When
      # stuff as well as the +test_that+ method you can
      # use to define tests a bit more fluently.
      #
      # Example
      #
      #     class TestCircle < Test::Unit::Given::TestCase
      #       test_that {
      #         Given { @circle = Circle.new(10) }
      #         When  { @area = @circle.area }
      #         Then  { assert_equal 314,@area }
      #       }
      #     end
      class TestCase < Test::Unit::TestCase
        include Simple
        include TestThat
        if RUBY_VERSION =~ /^1\.8\./
          # Avoid the stupid behavior of 
          # complaining that no tests were specified for 1.8.-like rubies
          def default_test
          end
        end
      end
    end
  end
end
