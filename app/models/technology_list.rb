class TechnologyList
  include Enumerable
  extend  Forwardable

  def_delegators :@list, :each, :keys, :to_h, :[]=, :delete, :empty?, :blank?

  # Public: Given a hash containing node keys, and a list of technologies
  # attached to the node, converts this into a TechnologyList where each tech
  # becomes an InstalledTechnology instance.
  #
  # Returns a TechnologyList.
  def self.load(data)
    data.blank? ? new({}) : from_hash(JSON.parse(data))
  end

  # Public: Given a hash containing node keys, and a list of technologies
  # attached to the node, converts this into a TechnologyList where each tech
  # becomes an InstalledTechnology instance.
  #
  # Returns a TechnologyList.
  def self.from_hash(data)
    profiles = self.load_profiles(data)

    new(Hash[data.map do |node_key, technologies|
      [node_key, technologies.map do |technology|
        InstalledTechnology.new(technology.update(
          'profile_key' => profiles[technology['profile']]
        ))
      end]
    end])
  end

  def self.load_profiles(data)
    profile_ids =
      data.values.flatten.map{ |t| t['profile'] }.uniq.reject do |key|
        ! key.is_a?(String) || ! key.is_a?(Integer)
      end

    Hash[LoadProfile.where(id: profile_ids).map do |load_profile|
      [load_profile.id, load_profile.key]
    end]
  end

  # Public: Given a TechnologyList, converts it back to the raw hash form for
  # storage in a database.
  #
  # Returns a hash.
  def self.dump(list)
    JSON.dump(Hash[list.to_h.map { |key, techs| [key, techs.map(&:to_h)] }])
  end

  # Public: Given a CSV file as a string, creates a TechnologyList.
  #
  # Parses the contents of the CSV into a new TechnologyList. The file is
  # expected to contain a header row naming each column, with a mandatory
  # "connection" column describing to which node the technology is attached.
  #
  # Returns a TechnologyList.
  def self.from_csv(csv)
    data = CSV.parse(csv, headers: true).each_with_object({}) do |row, data|
      data[row['connection']] ||= []
      data[row['connection']].push(row.to_h.except('connection'))
    end

    TechnologyList.from_hash(data)
  end

  # Returns the raw hash containing each technology keyed on it's owner node.
  attr_reader :list

  # Public: Creates a new TechnologyList. Contains the technologies defined
  # within a testing ground.
  def initialize(list = {})
    @list = list
  end

  # Public: Iterates through all technologies in the testing ground.
  def each_tech(&block)
    @list.values.flatten.each(&block)
  end

  # Public: Given a node key, returns the attached technologies in an array.
  def [](key)
    @list[key] || []
  end

  # Public: Converts the list to a JSON representation.
  def as_json(*)
    each_with_object({}) do |(node, techs), data|
      data[node] = techs.map(&:to_h)
    end
  end

  # Public: Converts the technology list to a CSV file.
  def to_csv
    attributes = InstalledTechnology::PRESENTABLES
    options    = { headers: [:connection, *attributes], write_headers: true }

    CSV.generate(options) do |csv|
      each do |connection, technologies|
        technologies.each do |technology|
          csv << [connection, *attributes.map{|attribute| technology.send(attribute) }]
        end
      end
    end
  end
end # TechnologyList
