module Calculation
  # Calculates consumption flows through the network.
  #
  # Based on the output of producers, we can determine how much excess or
  # deficit is available in the network in a given time-step. This excess is
  # then distributed fairly between the storage technologies.
  module PullConsumption
    module_function

    # Public: Computes energy flows through the network.
    #
    # Returns the context.
    def call(context)
      context.frames do |frame|
        context.subpaths.each do |paths|
          mandatory_consumption!(frame, context, paths)
          conditional_consumption!(frame, context, paths)
        end

        conservable_production!(frame, context)
      end

      context
    end

    # --

    # Internal: Push mandatory flows through the network.
    #
    # Returns nothing.
    def mandatory_consumption!(frame, context, paths)
      paths.each do |path|
        path.consume(frame, path.mandatory_consumption_at(frame))
      end
    end

    private_class_method :mandatory_consumption!

    def conditional_consumption!(frame, context, paths)
      paths.each do |path|
        wanted = path.conditional_consumption_at(frame)

        if path.subpath?
          path.consume(frame, wanted, true) if wanted > 0
        elsif path.excess_constrained?
          excess = path.excess_at(frame)

          if excess <= 0
            # Some technologies need to be explicitly told that they received
            # nothing, as they have further actions to take.
            path.consume(frame, 0.0, true)
          else
            assignable = excess < wanted ? excess : wanted
            path.consume(frame, assignable, true)
          end
        else
          path.consume(frame, path.conditional_consumption_at(frame), true)
        end
      end
    end

    private_class_method :conditional_consumption!

    # Internal: Send loads through the network where over-production results in
    # a (negative) capacity exceedance.
    #
    # Returns nothing.
    def conservable_production!(frame, context)
      return unless context.options[:strategies][:capping_solar_pv]

      context.paths.each do |path|
        conservable = path.technology.conservable_production_at(frame)

        if path.congested_at?(frame) && conservable > 0
          exceedance = path.production_exceedance_at(frame)
          amount     = conservable < exceedance ? conservable : exceedance

          path.consume(frame, amount, true)
        end
      end
    end

    private_class_method :conservable_production!
  end # PullConsumption
end # Calculation
