module LoadProfiles
  class Options
    #
    # Class to generate options for load profiles
    #
    def initialize(load_profiles, testing_ground, technology)
      @load_profiles = load_profiles[technology] || LoadProfile.order(:key)
      @testing_ground = testing_ground
    end

    def generate_options
      if selected_profiles.any?(&:deprecated?)
        @load_profiles
      else
        @load_profiles.reject(&:deprecated?)
      end
    end

    private

    def profile_ids
      @profile_ids ||= @testing_ground.technology_profile.list.values.flatten
        .map(&:profile).uniq
    end

    def selected_profiles
      @load_profiles.select do |profile|
        profile_ids.include?(profile.id)
      end
    end
  end
end