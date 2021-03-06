require 'rails_helper'

RSpec.describe TestingGround::TechnologyProfileScheme do
  describe "no buffers" do
    let!(:technology_profiles){
      5.times do
        FactoryGirl.create(:technology_profile,
                            technology: "households_solar_pv_solar_radiation")
      end

      5.times do
        FactoryGirl.create(:technology_profile,
                            technology: "transport_car_using_electricity")
      end
    }

    it 'minimizes concurrency' do
      new_profile = TestingGround::TechnologyProfileScheme.new(
        TechnologyDistributorData.load_file('solar_pv_distribution_two_nodes_lv1_and_lv2')
      ).build

      expect(new_profile.values.flatten.map{|t| t['profile'] }.uniq.count).to eq(2)
    end

    describe "maximizes concurrency with one technology to one node of a multi-node topology" do
      let(:new_profile){
        TestingGround::TechnologyProfileScheme.new(
          TechnologyDistributorData.load_file('solar_pv_nodes_maximize_lv1')
        ).build
      }

      it "expects only one profile" do
        expect(new_profile.values.flatten.map{|t| t['profile'] }.uniq.count).to eq(1)
      end

      it "expects only one technology" do
        expect(new_profile.values.flatten.count).to eq(1)
      end
    end

    describe "maximizes concurrency" do
      let(:new_profile){
        TestingGround::TechnologyProfileScheme.new(
          TechnologyDistributorData.load_file('solar_pv_distribution_minimized_concurrency_two_nodes_lv1_and_lv2')
        ).build
      }

      it "expects only one profile" do
        expect(new_profile.values.flatten.map{|t| t['profile'] }.uniq.count).to eq(1)
      end

      it "expects no duplicate entries per node" do
        expect(new_profile.values.flatten.length).to eq(2)
      end

      it "doesn't automatically fill in the demand" do
        expect(new_profile.values.flatten.map{|t| t['demand'] }).to eq([nil, nil])
      end
    end

    describe "minimizes concurrency with a subset of technologies" do
      let(:new_profile){
        TestingGround::TechnologyProfileScheme.new(
          TechnologyDistributorData.load_file('solar_pv_and_ev_distribution_two_nodes_lv1_and_lv2')
        ).build
      }

      it "expects only the electric car to have minimum concurrency" do
        # (5 profiles for each electric car + 1 profile for each solar panel)
        # x 2 endpoints = 12
        expect(new_profile.values.flatten.length).to eq(12)
      end
    end

    describe "EDSN profile usage" do
      let!(:profiles){
        5.times do |i|
          FactoryGirl.create(:technology_profile,
            technology: 'base_load',
            load_profile: FactoryGirl.create(:load_profile, key: "anonimous_#{i + 1}"))

          FactoryGirl.create(:technology_profile,
            technology: 'base_load_edsn',
            load_profile: FactoryGirl.create(:load_profile, key: "edsn_#{i + 1}"))
        end
      }

      describe "minimizes concurrency only with EDSN profiles" do
        let(:new_profile){
          distribution = TechnologyDistributorData.load_file('base_load_edsn')
          distribution[0]["units"] = 31.0

          TestingGround::TechnologyProfileScheme.new(distribution).build
        }

        it 'expects only EDSN profiles' do
          load_profile_id = new_profile.values.flatten.first["profile"]

          expect(LoadProfile.find(load_profile_id).key).to eq("edsn_1")
        end

        it "doesn't minimize" do
          expect(new_profile.values.flatten.length).to eq(1)
        end
      end

      describe "minimizes concurrency only with non-EDSN profiles" do
        let(:new_profile){
          distribution = TechnologyDistributorData.load_file('base_load')
          distribution[0]["units"] = 9.0

          TestingGround::TechnologyProfileScheme.new(distribution).build
        }

        it 'only makes use of non-EDSN profiles' do
          load_profile_id = new_profile.values.flatten.first["profile"]

          expect(LoadProfile.find(load_profile_id).key).to eq("anonimous_1")
        end
      end
    end
  end

  describe "buffers" do
    let!(:technology_profiles){
      5.times do |i|
          FactoryGirl.create(:technology_profile,
            technology: 'buffer_space_heating',
            load_profile: FactoryGirl.create(:load_profile, key: "bsh_#{i + 1}"))
      end
    }

    let(:new_profile){
      TestingGround::TechnologyProfileScheme.new(profile_scheme).build
    }

    describe 'minimizes concurrency with buffers' do
      let(:profile_scheme){
        TechnologyDistributorData.load_file('space_heater_buffers_two_nodes_lv1_and_lv2')
      }

      it 'minimizes concurrency with buffers' do
        expect(new_profile.values.flatten.map{|t| t['buffer'] }.compact).to eq([
          "buffer_space_heating_1", "buffer_space_heating_1",
          "buffer_space_heating_2", "buffer_space_heating_2",
          "buffer_space_heating_3", "buffer_space_heating_3",
          "buffer_space_heating_4", "buffer_space_heating_4",
          "buffer_space_heating_5", "buffer_space_heating_5"
        ])
      end
    end

    describe 'maximizes concurrency with buffers' do
      let(:profile_scheme){
        TechnologyDistributorData.load_file('space_heater_buffers_minimized_concurrency_two_nodes_lv1_and_lv2')
      }

      it 'maximizes concurrency with buffers' do
        expect(new_profile.values.flatten.count).to eq(3)
      end
    end
  end
end

