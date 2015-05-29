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
    let!(:technology){ FactoryGirl.create(:importable_technology,
                        key: "magical_technology") }

    it "renders the new template after performs an import" do
      sign_in(user)

      stub_et_engine_request
      stub_scenario_request

      post :perform_import, import: { scenario_id: 1 }

      expect(response).to render_template(:new)
    end
  end

  describe "#calculate_concurrency" do
    let(:topology){ FactoryGirl.create(:topology).graph.to_json }

    describe "maximum profile differentiation" do
      it "combines a testing ground topology with a set of technologies" do
        sign_in(user)

        post :calculate_concurrency,
              profile: profile_json,
              topology: topology,
              profile_differentiation: 'max',
              format: :js

        result = controller.instance_variable_get("@testing_ground_profile").as_json

        expect(result.values.flatten.count).to eq(4)
        expect(result.keys.count).to eq(2)
      end
    end

    describe "minimum profile differentiation" do
      it "combines a testing ground topology with a set of technologies and no profiles" do
        sign_in(user)

        post :calculate_concurrency,
              profile: profile_json,
              topology: topology,
              profile_differentiation: 'min',
              format: :js

        result = controller.instance_variable_get("@testing_ground_profile").as_json

        expect(result.values.flatten.count).to eq(4)
        expect(result.keys.count).to eq(2)
      end

      it "combines a testing ground topology with a set of technologies and the same amount of profiles as technologies" do
        5.times{ FactoryGirl.create(:technology_profile,
                    technology: 'households_solar_pv_solar_radiation') }

        5.times{ FactoryGirl.create(:technology_profile,
                    technology: 'transport_car_using_electricity') }

        sign_in(user)

        post :calculate_concurrency,
              profile: profile_json,
              topology: topology,
              profile_differentiation: 'min',
              format: :js

        result = controller.instance_variable_get("@testing_ground_profile").as_json

        expect(result.values.flatten.map{|t| t[:profile]}.uniq.length).to eq(10)
      end

      it "combines a testing ground topology with a set of technologies with less profiles than technologies" do
        2.times{ FactoryGirl.create(:technology_profile,
                  technology: 'households_solar_pv_solar_radiation') }

        sign_in(user)

        post :calculate_concurrency,
              profile: profile_json,
              topology: topology,
              profile_differentiation: 'min',
              format: :js

        result = controller.instance_variable_get("@testing_ground_profile").as_json

        expect(result.values.flatten.map{|t| t[:profile]}.uniq.length).to eq(3)
        expect(result.values.flatten.length).to eq(6)
      end
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

    it "assings the testing ground to the current user" do
      sign_in(user)

      expect_any_instance_of(TestingGround).to receive(:valid?).and_return(true)
      post :create, TestingGroundsControllerTest.create_hash

      expect(TestingGround.last.user).to eq(controller.current_user)
    end
  end

  describe "#data.json" do
    it "shows the data of a testing ground" do
      sign_in(user)

      testing_ground = FactoryGirl.create(:testing_ground)

      get :data, format: :json, id: testing_ground.id

      expect(JSON.parse(response.body)).to eq(TestingGroundsControllerTest.show_hash)
    end

    it "denies permission for the data of a private testing grounds" do
      sign_in(user)

      testing_ground = FactoryGirl.create(:testing_ground, permissions: 'private')

      get :data, format: :json, id: testing_ground.id

      expect(response.status).to eq(403)
    end
  end

  describe "#show" do
    it "shows a testing ground" do
      sign_in(user)

      testing_ground = FactoryGirl.create(:testing_ground)

      get :show, id: testing_ground.id

      expect(response.status).to eq(200)
    end

    it "doesn't show a testing ground when it's private" do
      sign_in(user)

      testing_ground = FactoryGirl.create(:testing_ground,
                                          permissions: 'private')

      get :show, id: testing_ground.id

      expect(response).to redirect_to(testing_grounds_path)
    end

    it "shows a testing ground when it's private" do
      sign_in(user)

      testing_ground = FactoryGirl.create(:testing_ground,
                                          user: user,
                                          permissions: 'private')

      get :show, id: testing_ground.id

      expect(response.status).to eq(200)
    end
  end

  describe "#export" do
    it "visits export path" do
      sign_in(user)

      testing_ground = FactoryGirl.create(:testing_ground)

      get :export, id: testing_ground.id

      expect(response.status).to eq(200)
    end
  end

  describe "#technology_profile" do
    it "exports csv file" do
      sign_in(user)

      testing_ground = FactoryGirl.create(:testing_ground,
                                           technology_profile: {"lv1" => []})

      get :technology_profile, id: testing_ground.id, format: :csv

      expect(response.status).to eq(200)
    end
  end

  describe "#edit" do
    it "visits edit path" do
      sign_in(user)

      testing_ground = FactoryGirl.create(:testing_ground,
                                           technology_profile: {"lv1" => []})

      get :edit, id: testing_ground.id

      expect(response.status).to eq(200)
    end

    it "doesn't show the edit page of a testing ground when it's private" do
      sign_in(user)

      testing_ground = FactoryGirl.create(:testing_ground,
                                          permissions: 'private')

      get :edit, id: testing_ground.id

      expect(response).to redirect_to(testing_grounds_path)
    end

    it "shows the edit page of a testing ground when it's private" do
      sign_in(user)

      testing_ground = FactoryGirl.create(:testing_ground,
                                          user: user,
                                          permissions: 'private')

      get :edit, id: testing_ground.id

      expect(response.status).to eq(200)
    end
  end

  describe "#update" do
    let!(:technologies){
      FactoryGirl.create(:technology,
        key: 'households_solar_pv_solar_radiation')

      FactoryGirl.create(:technology,
        key: 'transport_car_using_electricity')
    }

    let(:topology){
      FactoryGirl.create(:large_topology)
    }

    let(:testing_ground){
      FactoryGirl.create(:testing_ground, name: "Hello world",
                                          topology: topology,
                                          technology_profile: {"lv1" => []}) }

    let(:private_testing_ground){
      testing_ground.update_column(:permissions, "private")
      testing_ground
    }

    let(:update_hash){
      TestingGroundsControllerTest.update_hash
    }

    it "updates testing ground" do
      sign_in(user)

      patch :update, id: testing_ground.id,
                   testing_ground: update_hash

      expect(testing_ground.reload.name).to eq("2015-08-02 - Test123")
    end

    it "doesn't update a private testing ground" do
      sign_in(user)

      patch :update, id: private_testing_ground.id,
                   testing_ground: update_hash

      expect(response).to redirect_to testing_grounds_path
    end

    it "updates testing ground with a csv" do
      sign_in(user)

      patch :update, id: testing_ground.id,
        testing_ground: update_hash.merge({
          technology_profile_csv: fixture_file_upload("technology_profile.csv",
                                                      "text/csv")
        })

      expect(testing_ground.reload.technology_profile["lv1"][0].profile).to eq("solar_tv_zwolle")
    end
  end
end
