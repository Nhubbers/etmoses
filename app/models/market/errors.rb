module Market
  # Error class which serves as a base for all errors which occur in the
  # Market module.
  class Error < RuntimeError
    def initialize(*args)
      super(make_message(*args))
    end

    def make_message(msg)
      msg
    end
  end

  # Internal: Creates a new error class which inherits from AtlasError,
  # whose message is created by evaluating the block you give.
  #
  # For example
  #
  #   MyError = error_class do |weight, limit|
  #     "#{ weight } exceeds #{ limit }"
  #   end
  #
  #   fail MyError.new(5000, 2500)
  #   # => #<Atlas::MyError: 5000 exceeds 2500>
  #
  # Returns an exception class.
  def self.error_class(superclass = Error, &block)
    Class.new(superclass) { define_method(:make_message, &block) }
  end

  NoSuchMeasureError = error_class do |name|
    "No such measure: #{ name.inspect }"
  end

  InvalidTariffError = error_class do |tariff|
    "Invalid tariff: #{ tariff.inspect }"
  end

  NoLoadError = error_class do |node|
    "Tried to fetch load on #{ node.key }, but none is set. Has the network " \
    "been calculated?"
  end
end
