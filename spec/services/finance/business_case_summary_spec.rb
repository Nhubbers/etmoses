require 'rails_helper'

RSpec.describe Finance::BusinessCaseSummary do
  let(:financials){
    [ {"aggregator"      =>[0,   nil, nil,     nil, nil, nil, nil]},
      {"cooperation"     =>[nil, 0,   nil,     nil, nil, nil, nil]},
      {"customer"        =>[nil, nil, 0,       nil, nil, nil, nil]},
      {"government"      =>[nil, nil, nil,     0,   nil, nil, nil]},
      {"producer"        =>[nil, nil, nil,     nil, 0,   nil, nil]},
      {"supplier"        =>[nil, nil, nil,     nil, nil, 0,   nil]},
      {"system operator" =>[nil, nil, 44150.4, nil, nil, nil, 9998]}  ]
  }

  let(:business_case){ FactoryGirl.create(:business_case, financials: financials) }

  it "gives the business case summary" do
    expect(Finance::BusinessCaseSummary.new(business_case).summarize).to eq([
      {:stakeholder=>"aggregator",      :incoming=>0,       :outgoing=>0,       :freeform=>0, :total=>0},
      {:stakeholder=>"cooperation",     :incoming=>0,       :outgoing=>0,       :freeform=>0, :total=>0},
      {:stakeholder=>"customer",        :incoming=>0,       :outgoing=>44150.4, :freeform=>0, :total=>-44150.4},
      {:stakeholder=>"government",      :incoming=>0,       :outgoing=>0,       :freeform=>0, :total=>0},
      {:stakeholder=>"producer",        :incoming=>0,       :outgoing=>0,       :freeform=>0, :total=>0},
      {:stakeholder=>"supplier",        :incoming=>0,       :outgoing=>0,       :freeform=>0, :total=>0},
      {:stakeholder=>"system operator", :incoming=>44150.4, :outgoing=>9998,    :freeform=>0, :total=>34152.4}
    ])
  end
end
