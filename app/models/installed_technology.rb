class InstalledTechnology
  include Virtus.model

  attribute :node,                                String
  attribute :name,                                String
  attribute :buffer,                              String
  attribute :composite,                           Boolean, default: false
  attribute :composite_index,                     Integer
  attribute :composite_value,                     String
  attribute :position_relative_to_buffer,         String
  attribute :type,                                String, default: 'generic'
  attribute :behavior,                            String
  attribute :profile,                             Integer
  attribute :profile_key,                         String
  attribute :capacity,                            Float
  attribute :demand,                              Float
  attribute :volume,                              Float
  attribute :units,                               Integer, default: 1
  attribute :initial_investment,                  Float
  attribute :technical_lifetime,                  Integer
  attribute :performance_coefficient,             Float
  attribute :concurrency,                         String,  default: 'max'
  attribute :full_load_hours,                     Integer
  attribute :om_costs_per_year,                   Float
  attribute :om_costs_per_full_load_hour,         Float
  attribute :om_costs_for_ccs_per_full_load_hour, Float
  attribute :associates,                          Array[InstalledTechnology]
  attribute :includes,                            Array[String]
  attribute :congestion_reserve_percentage,       Float

  EDITABLES = %i(name buffer type profile carrier_capacity volume demand units
    initial_investment technical_lifetime full_load_hours om_costs_per_year
    om_costs_per_full_load_hour om_costs_for_ccs_per_full_load_hour
    performance_coefficient concurrency composite composite_value
    position_relative_to_buffer includes composite_index congestion_reserve_percentage
  )

  HIDDEN = %i(initial_investment technical_lifetime full_load_hours om_costs_per_year
    om_costs_per_full_load_hour om_costs_for_ccs_per_full_load_hour
    performance_coefficient concurrency includes composite_index
  )

  PRESENTABLES = (EDITABLES - %i(carrier_capacity concurrency) + %i(capacity))

  def initialize(args = nil)
    @id = SecureRandom.hex

    super
  end

  # Public: Returns a template for a technology. For evaluation purposes
  def self.template
    Hash[ self.attribute_set.map do |attr|
      [attr.name.to_s, attr.default_value.call]
    end ]
  end

  def inspect
    "#<#{ self.class.name } #{ to_s }>"
  end

  def to_s
    "#{ name } ( #{ [type, buffer, composite_value].compact.join(", ") })"
  end

  # Public: Set the profile to be used to describe the technology load over
  # time.
  #
  # profile - A string describing the profile: either a load profile key, or a
  #           JSON-style array as a string.
  #
  # Returns the profile name.
  def profile=(profile)
    if profile && profile.is_a?(String) && profile.match(/\A\[.*\]\z/)
      super(JSON.parse(profile))
    else
      super
    end
  end

  # Public: Returns if the technology has been defined in the data/technologies
  # directory.
  #
  # "Freeform" (no "type") technologies will return true.
  #
  # Returns true or false.
  def exists?
    type.blank? || Technology.exists?(key: type)
  end

  # Public: Returns the associated technology (as defined in data/technologies).
  # Techs with no "type" will return the "generic" library tech.
  #
  # Returns a Technology, or raises ActiveRecord::RecordNotFound if the tech
  # does not exist.
  def technology
    type.present? ? Technology.by_key(type) : Technology.generic
  end

  # Public: Describes the electrical capacity of the technology.
  #
  # The "full" capacity of some technologies includes energy which comes from
  # non-electrical sources. For example, heat pumps derive a large portion of
  # their energy from ambient heat.
  #
  # Returns a numeric.
  def carrier_capacity
    capacity.presence && capacity / performance_coefficient
  end

  # Public: Sets a new electrical capacity. Also sets the main capacity
  # attribute.
  #
  # If the technology has a performance coefficient, the main capacity will be
  # adjusted appropriately.
  #
  # Returns the given value.
  def carrier_capacity=(value)
    if value.present?
      @recent_carrier_capacity = value.to_f
      self.capacity = value.to_f * performance_coefficient
    else
      self.capacity = @recent_carrier_capacity = nil
    end
  end

  # Public: How many units of this technology are installed?
  #
  # Returns a numeric.
  def units
    super.presence || 1
  end

  # Public: Describes the real capcity of the technology in relation to its
  # electrical capacity.
  #
  # Performance coefficient is the amount by which the electrical capacity
  # should be multiplied in order to arrive at the technologys real capacity.
  #
  # For example, a heat pump may have an electrical capacity of 2.5 and a
  # coefficient of 4.0. This means that the technology will receive 7.5 kW from
  # other sources for every 2.5 it receives in electrical energy.
  #
  # Returns a numeric.
  def performance_coefficient
    super.presence || 1.0
  end

  # Public: Sets the performance coefficient of this technology.
  #
  # If an electrical capacity has recently been set, changing the coefficient
  # will adjust the main capacity attribute as appropriate.
  #
  # Returns given coefficient.
  def performance_coefficient=(value)
    super(value == 0 ? 1.0 : value)

    if @recent_carrier_capacity
      # If the user set the electrical capacity prior to the COP, we need to
      # re-set the capacity so that it correctly accounts for performance.
      self.carrier_capacity = @recent_carrier_capacity
    end
  end

  # Public: The carrier (energy type) used by this technology.
  #
  # Returns a Symbol.
  def carrier
    technology.carrier.to_sym
  end

  # Public: Determines the network behavior of this technology with a particular
  # curve type. Base load technologies will behave differently depending on the
  # use of a flexible or inflexible curve.
  #
  # Returns a string.
  def behavior_with_curve(curve_type = nil)
    behavior = self.behavior.presence || technology.behavior

    return behavior if curve_type.nil? || curve_type == 'default'.freeze

    component_behavior = technology.component_behaviors.for_type(curve_type)
    component_behavior.try(:behavior) || behavior
  end

  # Public: Returns the load profile Curve, if the :profile attribute is set.
  #
  # Returns a Hash[{ <curve_type> => Network::Curve }]
  def profile_curve
    if profile.nil?
      { default: nil }
    elsif profile.is_a?(Array)
      curve = Network::Curve.new(profile)
      { default: curve * component_factor(curve) }
    elsif profile.is_a?(Hash)
      Hash[profile.each_pair.map do |curve_type, curve|
        [curve_type, Network::Curve.new(curve)]
      end]
    elsif demand
      profile_curves(:demand_scaled)
    elsif volume.blank? && capacity
      profile_curves(:capacity_scaled)
    else
      profile_curves
    end
  end

  def each_profile_curve
    if has_heat_pump_profiles?
      yield(profile_curve.keys.sort.join('_'), *profile_curve.values)
    else
      profile_curve.each_pair.map do |curve_type, curve|
        yield(curve_type, curve)
      end
    end
  end

  def as_json(*)
    super.merge('carrier_capacity' => carrier_capacity)
  end

  def yearly_investment
    om_costs_per_year.to_f                   +
    initial_investment.to_f                  / (technical_lifetime || 1) +
    om_costs_per_full_load_hour.to_f         / (full_load_hours || 1) +
    om_costs_for_ccs_per_full_load_hour.to_f / (full_load_hours || 1)
  end

  def parent_key
    buffer && !composite ? buffer : ''
  end

  def get_composite_value
    "#{type}_#{composite_index}"
  end

  def get_composite_name
    if name =~ /\#[0-9]+/
      name.sub(/[0-9]+/, composite_index.to_s)
    else
      "#{name} ##{composite_index}"
    end
  end

  def get_buffer(buffer)
    "#{buffer}_#{composite_index}"
  end

  def position_relative_to_buffer_name
    "position_relative_to_buffer_#{@id}_#{type}"
  end

  def valid?
    buffer.present? || valid_profile? || is_battery?
  end

  def valid_profile?
    if profile.is_a?(Hash)
      profile.present?
    else
      profile.present? && load_profile.present?
    end
  end

  def is_battery?
    type == 'neighbourhood_battery'
  end

  private

  def has_heat_pump_profiles?
    profile_curve.keys.sort == %w(availability use)
  end

  # Internal: Retrieves the Network::Curve used by the technology, with
  # scaling applied for demand or capacity and a ratio.
  #
  # Returns a Hash[{ <curve_type> => Network::Curve }].
  def profile_curves(scaling = nil)
    return {} unless valid_profile?

    Hash[load_profile.curves.each_curve(scaling).map do |curve_type, curve, ratio|
      [curve_type, curve * component_factor(curve) * ratio]
    end]
  end

  def component_factor(curve)
    factor =
      if composite
        (demand && demand * curve.frames_per_hour) || 1.0
      else
        volume || capacity || (demand && demand * curve.frames_per_hour) || 1.0
      end

    (factor / performance_coefficient) * units
  end

  def load_profile
    @load_profile ||= LoadProfile.find_by_id(profile)
  end
end # end
