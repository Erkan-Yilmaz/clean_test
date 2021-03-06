require 'faker'

module Clean #:nodoc:
  module Test #:nodoc:
    # Public: Provides the ability to vend arbitrary values without using literals, or
    # long calls to Faker.  This has two levels of utility:
    #
    # helper methods - #any_number, #any_int, #any_string provide arbitrary primitives 
    #                  to make it clear what numbers, ints, and strings in your tests are
    #                  relevant.  Arbitrary values should use one of these any_ helpers.
    #
    # any sort of any - you can define your own "any" values by using #new_any, which allows you to 
    #                   extend things if you like.  Of course, you could just make your own any_method as well.
    #
    # Example:
    #
    #     class Person
    #       def initialize(first_name,last_name,age)
    #         # ...
    #       end
    #     end
    #
    #     test_that "someone under 18 is a minor" {
    #       Given {
    #         # First name and last name aren't relevant to the test
    #         @person = Person.new(any_string,any_string,17)
    #       }
    #       When {
    #         @minor = @person.minor?
    #       }
    #       Then {
    #         assert @minor
    #       }
    #     }
    #
    #     test_that "full_name gives the full name" {
    #       Given {
    #         # Age isn't relevant; it just needs to be positive
    #         @person = Person.new("Dave","Copeland",any_int :positive)
    #       }
    #       When {
    #         @full_name = @person.full_name
    #       }
    #       Then {
    #         assert_equal "Dave Copeland",@full_namej
    #       }
    #     }
    module Any
      def self.included(k)
        seed = if ENV['RANDOM_SEED']
                 ENV['RANDOM_SEED'].to_i
               else
                 srand() # generate random seed
                 seed = srand() # save it (but we've now generated another one)
               end
        srand(seed) # set it explicitly
        puts "Random seed was #{seed}; re-use it via environment variable RANDOM_SEED"
      end
      MAX_RAND = 50000 #:nodoc:

      # Public: Get any number; one that doesn't matter
      #
      # options - options to control what sort of number comes back:
      #           :positive - make sure that the number is greater than zero
      #           :negative - make sure that the number is less than zero
      def any_number(*options)
        any :number,options
      end

      # Public: Returns an integer.  options is the same as for #any_number
      def any_int(*options)
        any :int,options
      end

      # Public: Get an arbitrary string of any potential positive length
      #
      # options - options to control the returned string:
      #           :max - the max size of the string you want, must be positive and greater than :min
      #           :min - the minimum size we want to come back, must be positive and less than :max
      #
      # Example
      #
      #     any_string :max => 255 # => ensure it'll fit into a varchar(255)
      #     any_string :min => 1024 # at least 1024 characters
      #
      def any_string(options = {})
        any :string,options
      end

      # Public: Get an arbitrary symbol, for example to use as a Hash key.  The symbol
      # will be between 2 and 20 characters long.  If you need super-long symbols for some reason,
      # use <code>any_string.to_sym</code>.
      def any_symbol
        (any_string :min => 2, :max => 20).to_sym
      end

      # Public: Get an arbitrary sentence of arbitrary words of any potential length.  Currently,
      # this returns a sentence between 10 and 21 words, though you can control that with options
      #
      # options - options to control the returned sentence
      #           :max - the maximum number of words you want returned
      #           :min - the minimum number of words you want returned; the sentence will be between
      #                  :min and (:min + 10) words
      #
      # Example
      #
      #     any_sentence :min => 20  # at least a 20-word sentence
      #     any_sentence :max => 4   # no more than four words
      #
      def any_sentence(options = {})
        any :sentence,options
      end

      # Public: Get a predefined, arbitrary any.  
      #
      # sym - the any that has been defined already.  By default, the following are defined:
      #       :string - does any_string
      #       String  - does any_string
      #       :number  - does any_number
      #       Numeric  - does any_number
      #       Float  - does any_number
      #       :int  - does any_int
      #       Fixnum  - does any_int
      #       Integer  - does any_int
      # options - whatever options are relevant to the user-defined any
      #
      # Example
      #
      #     new_any(:foo) do |options|
      #       if options[:bar]
      #         'bar'
      #       else
      #         'quux'
      #       end
      #     end
      #
      #     some_foo = any :foo
      #     some_other_foo = any :foo, :bar => true
      def any(sym,options = {})
        anies[sym].call(options)
      end

      # Public: Create a new any that can be retrieved via #any
      #
      # any - the identifer of your new any. Can be anything though a Symbol or classname would be appropriate
      # block - the block that will be called whenever you #any your any.
      def new_any(any,&block)
        anies[any] = block
      end

      private

      def anies
        @anies ||= default_anies
      end

      ANY_STRING = Proc.new do |options| #:nodoc:
        if options[:min] && options[:max]
          raise ":min must be less than :max" if options[:min] > options[:max]
        end
        if options[:min]
          raise ":min must be positive" if options[:min] < 1
        end

        min_size = options[:min]
        max_size = options[:max]

        if min_size.nil? && max_size.nil?
          min_size = rand(80) + 1
          max_size = min_size + rand(80)
        elsif min_size.nil?
          min_size = max_size - rand(max_size)
          min_size = 1 if min_size < 1
        else
          max_size = min_size + rand(min_size) + 1
        end

        string = Faker::Lorem.words(1).join(' ')
        while string.length < min_size
          string += Faker::Lorem.words(1).join(' ') 
        end

        string[0..(max_size-1)]
      end

      ANY_NUMBER = Proc.new do |options| #:nodoc:
        number = (rand(2 * MAX_RAND) - MAX_RAND).to_f/100.0
        if options.include? :positive
          number + MAX_RAND
        elsif options.include? :negative
          number - MAX_RAND
        else
          number
        end
      end

      ANY_SENTENCE = Proc.new do |options| #:nodoc:
        min = 11
        max = 21

        if options[:max]
          min = 1
          max = options[:max]
        elsif options[:min]
          min = options[:min]
          max = min + 10
        end

        Faker::Lorem.words(rand(max - min) + min).join(' ')
      end

      ANY_INT = Proc.new do |options| #:nodoc:
        (ANY_NUMBER.call(options)).to_i
      end

      def default_anies
        { :string => ANY_STRING,
          String => ANY_STRING,
          :number => ANY_NUMBER,
          Numeric => ANY_NUMBER,
          Float => ANY_NUMBER,
          :int => ANY_INT,
          Fixnum => ANY_INT,
          Integer => ANY_INT,
          :sentence => ANY_SENTENCE,
        }
      end
    end
  end
end

