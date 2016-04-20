module Network
  module Technologies
    module Composite
      # Wraps technologies which are part of a component to ensure that the
      # depleting profile is correctly adjusted for received energy.
      #
      # The delegator is based on Buffer, since it is the most complex of the
      # technologies modelled. This is not particularly future-proof: if another
      # technology is added with public methods not defined by Buffer, the
      # delegation will not work correctly (raising a NoMethodError).
      class Wrapper < FastDelegator.create(Buffer)
        def initialize(obj, composite)
          super(obj)
          @composite = composite
          @handle_decay = obj.respond_to?(:stored)
        end

        def production_at(frame)
          # Force evaluation of buffer decay.
          stored.at(frame) if @handle_decay
          super
        end

        def store(frame, amount)
          super
          profile.deplete(frame, amount)
        end

        def receive_mandatory(frame, amount)
          super
          profile.deplete(frame, amount)
        end

        # Public: Returns if the technology is a buffering technology. If false,
        # it is "boosting".
        #
        # Returns true or false.
        def buffering?
          false
        end

        def inspect
          "#<#{ self.class.name } #{ __getobj__.inspect }>"
        end
      end # Wrapper
    end # Composite
  end
end