module Market
  # Connects two stakeholders, describing an interaction; typically energy for
  # money.
  class Relation < Turbine::Edge
    # Public: The nodes whose values should be measured in order to determine
    # the price of the relation. These are the network nodes belonging to the
    # leaf nodes in the market graph.
    #
    # Returns an array of Network::Node instances.
    def measurables
      @measurables ||= from.descendants
        .select { |n| n.out_edges.none? }
        .get(:measurables).uniq.to_a
    end

    # Public: Determines the price of the relation. Provide the frames to be
    # calculated.
    #
    # Returns a numeric.
    def price(frames = nil)
      get(:rule).call(self, frames)
    end
  end
end