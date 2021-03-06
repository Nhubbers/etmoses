class BusinessCase < ActiveRecord::Base
  belongs_to :testing_ground
  belongs_to :job, class: Delayed::Job

  serialize :financials, JSON

  def freeform
    if financials
      financials.detect { |r| r['freeform'] } || empty_freeform
    else
      empty_freeform
    end
  end

  def financials=(financials)
    if financials.is_a?(Array)
      super(financials)
    elsif financials.is_a?(String)
      super(JSON.parse(financials))
    end
  end

  def clear_job!
    update_attributes(job_finished_at: nil, job_id: nil)
  end

  private

  def empty_freeform
    { 'freeform' => [nil] * financials.size }
  end
end
