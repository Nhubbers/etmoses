module NetworkCache
  class Validator
    include CacheHelper

    def self.from(testing_ground, opts = {})
      new(testing_ground, opts)
    end

    def valid?
      cache_intact? && identical_strategies? && fresh?
    end

    private

    def cache_intact?
      tree_scope.nodes.all? do |node|
        File.exists?(file_name(node.key))
      end
    end

    def identical_strategies?
      @opts.empty? || strategy_attributes == @opts
    end

    def fresh?
      [ @testing_ground,
        @testing_ground.topology,
        @testing_ground.market_model ].all? do |target|
        Time.at(target.updated_at.to_time.to_i) <= Time.at(cache_time.to_i)
      end
    end

    def cache_time
      tree_scope.nodes.map{|n| File.mtime(file_name(n.key)) }.min
    end

    def strategy_attributes
      @testing_ground.selected_strategy.attributes.except("id", "testing_ground_id")
    end
  end
end