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
end