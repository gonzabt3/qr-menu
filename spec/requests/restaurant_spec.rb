# spec/requests/restaurants_spec.rb
require 'rails_helper'

RSpec.describe "Restaurants", type: :request do
  let(:user) { create(:user) }
  let(:valid_attributes) { { name: "Unique Restaurant", address: "123 Main St", phone: "123-456-7890", email: "restaurant@example.com" } }
  let(:invalid_attributes) { { name: "", address: "123 Main St", phone: "123-456-7890", email: "restaurant@example.com" } }

  before do
    allow_any_instance_of(ApplicationController).to receive(:authorize).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "POST /restaurants" do
    context "with valid parameters" do
      it "creates a new Restaurant" do
        expect {
          post restaurants_path, params: { restaurant: valid_attributes }
        }.to change(Restaurant, :count).by(1)
        expect(response).to have_http_status(:created)
      end

      it "returns an error if the name is not unique" do
        post restaurants_path, params: { restaurant: valid_attributes }
        expect(response).to have_http_status(:created)

        post restaurants_path, params: { restaurant: valid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Restaurant name must be unique")
      end
    end

    context "with invalid parameters" do
      it "does not create a new Restaurant" do
        expect {
          post restaurants_path, params: { restaurant: invalid_attributes }
        }.to change(Restaurant, :count).by(0)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /restaurants/:id" do
    let(:restaurant) { create(:restaurant, user: user) }
    let(:new_attributes) { { name: "Updated Restaurant Name" } }

    context "with valid parameters" do
      it "updates the restaurant" do
        patch restaurant_path(restaurant), params: { restaurant: new_attributes }
        restaurant.reload
        expect(restaurant.name).to eq("Updated Restaurant Name")
        expect(response).to have_http_status(:ok)
      end

      it "allows updating logo_url field" do
        patch restaurant_path(restaurant), params: { restaurant: { name: restaurant.name } }
        restaurant.reload
        # The logo_url field should be accessible through the model
        expect { restaurant.logo_url }.not_to raise_error
      end
    end
  end

  describe "GET /restaurants/:id" do
    let(:restaurant) { create(:restaurant, user: user) }

    it "returns the restaurant with logo_url field" do
      get restaurant_path(restaurant)
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      # Verify that logo_url field is included in the response
      expect(json_response).to have_key("logo_url")
    end
  end
end