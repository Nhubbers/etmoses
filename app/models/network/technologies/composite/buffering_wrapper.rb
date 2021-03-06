module Network
  module Technologies
    module Composite
      # Wraps around a technology whose consumption is constrained by the
      # capacity of the composite, and which may include conditional consumption
      # where excesses are stored in Reserve for use in later frames.
      class BufferingWrapper < Wrapper
        def store(frame, amount)
          super
          @composite.input(frame, amount)
        end

        def receive_mandatory(frame, amount)
          super
          @composite.input(frame, amount)
        end

        def mandatory_consumption_at(frame)
          constrain(frame, super)
        end

        def conditional_consumption_at(frame)
          constrain(frame, super)
        end

        def buffering?
          true
        end

        private

        def constrain(frame, amount)
          margin = @composite.consumption_margin_at(frame)
          amount < margin ? amount : margin
        end
      end # BufferingWrapper
    end # Composite
  end
end
