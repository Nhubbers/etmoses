require 'rails_helper'

RSpec.describe TestingGroundsController do
  let(:user){ FactoryGirl.create(:user) }

  it "visits the import path" do
    user = FactoryGirl.create(:user)
    sign_in(user)

    get :import

    expect(response.status).to eq(200)
  end

  describe "#perform_import" do
    let(:user){ FactoryGirl.create(:user) }
    let!(:topology){ FactoryGirl.create(:topology, name: "Default topology")}
    let!(:technology){ FactoryGirl.create(:technology,
                        key: "magical_technology",
                        import_from: "input_capacity") }

    it "renders the new template after performs an import" do
      sign_in(user)

      stub_et_engine_request
      stub_scenario_request

      post :perform_import, import: { scenario_id: 1 }

      expect(response).to render_template(:new)
    end
  end

  describe "#calculate_concurrency" do
    describe "maximum profile differentiation" do
      it "combines a testing ground topology with a set of technologies" do
        sign_in(user)

        post :calculate_concurrency,
              profile: profile_json,
              profile_differentiation: 'max'

        expect(JSON.parse(response.body).values.flatten.count).to eq(6)
        expect(JSON.parse(response.body).keys.count).to eq(3)
      end
    end

    describe "minimum profile differentiation" do
      it "combines a testing ground topology with a set of technologies and no profiles" do
        sign_in(user)

        post :calculate_concurrency,
              profile: profile_json,
              profile_differentiation: 'min'

        expect(JSON.parse(response.body).values.flatten.count).to eq(6)
        expect(JSON.parse(response.body).keys.count).to eq(3)
      end

      it "combines a testing ground topology with a set of technologies and the same amount of profiles as technologies" do
        3.times{ FactoryGirl.create(:technology_profile,
                    technology: 'households_solar_pv_solar_radiation') }

        3.times{ FactoryGirl.create(:technology_profile,
                    technology: 'transport_car_using_electricity') }

        sign_in(user)

        post :calculate_concurrency,
              profile: profile_json,
              profile_differentiation: 'min'

        expect(JSON.parse(response.body).values.flatten.map{|t| t['profile']}.uniq.length).to eq(6)
      end

      it "combines a testing ground topology with a set of technologies with less profiles than technologies" do
        2.times{ FactoryGirl.create(:technology_profile,
                  technology: 'households_solar_pv_solar_radiation') }

        sign_in(user)

        post :calculate_concurrency,
              profile: profile_json,
              profile_differentiation: 'min'

        expect(JSON.parse(response.body).values.flatten.map{|t| t['profile']}.uniq.length).to eq(3)
        expect(JSON.parse(response.body).values.flatten.length).to eq(6)
      end
    end

    def profile_json
      '{"LV #1":[{"node":"LV #1","type":"households_solar_pv_solar_radiation","name":"Residential PV panel","units":"38","capacity":"-1.5","profile":"solar_pv_zwolle"},{"node":"LV #1","type":"transport_car_using_electricity","name":"Electric car","units":"7","capacity":"3.7","profile":"ev_profile_11_3.7_kw"}],"LV #2":[{"node":"LV #2","type":"households_solar_pv_solar_radiation","name":"Residential PV panel","units":"38","capacity":"-1.5","profile":"solar_pv_zwolle"},{"node":"LV #2","type":"transport_car_using_electricity","name":"Electric car","units":"7","capacity":"3.7","profile":"ev_profile_11_3.7_kw"}],"LV #3":[{"node":"LV #3","type":"households_solar_pv_solar_radiation","name":"Residential PV panel","units":"37","capacity":"-1.5","profile":"solar_pv_zwolle"},{"node":"LV #3","type":"transport_car_using_electricity","name":"Electric car","units":"7","capacity":"3.7","profile":"ev_profile_11_3.7_kw"}]}'
    end
  end

  describe "#create" do
    it "creates a testing ground" do
      sign_in(user)

      expect_any_instance_of(TestingGround).to receive(:valid?).and_return(true)
      post :create, TestingGroundsControllerTest.create_hash

      expect(TestingGround.count).to eq(1)
    end

    it "redirects to show page" do
      sign_in(user)

      expect_any_instance_of(TestingGround).to receive(:valid?).and_return(true)
      post :create, TestingGroundsControllerTest.create_hash

      expect(response).to redirect_to(testing_ground_path(TestingGround.last))
    end
  end

  describe "#show.json" do
    it "shows the data of a testing ground" do
      sign_in(user)

      testing_ground = FactoryGirl.create(:testing_ground)

      get :show, format: :json, id: testing_ground.id

      expect(JSON.parse(response.body)).to eq(TestingGroundsControllerTest.show_hash)
    end
  end
end
