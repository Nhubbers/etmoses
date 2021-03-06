class LoadProfileComponent < ActiveRecord::Base
  include CurveComponent

  CURVE_TYPES = { base_load: %w(flex inflex),
                  heat_pump: %w(use availability),
                  default:   %w(default) }

  belongs_to :load_profile

  has_attached_file :curve, styles: {
    demand_scaled:   { scale_by: :sum, processors: [:scaled_curve] },
    capacity_scaled: { scale_by: :max, processors: [:scaled_curve]}
  }

  validates_presence_of :curve_type
  validates_attachment :curve, presence: true,
    content_type: { content_type: CurveComponent::VALID_CSV_TYPES },
    size: { less_than: 100.megabytes }

  def filename
    "#{ load_profile.display_name.gsub(/[^0-9A-Za-z.\-]/, '_') }.#{ curve_type }.csv"
  end
end
