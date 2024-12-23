# spec/controllers/restaurants_controller_spec.rb
require 'rails_helper'

RSpec.describe RestaurantsController, type: :controller do
  let(:user) { create(:user) }
  let(:restaurant) { create(:restaurant, user: user) }
  let(:valid_attributes) {
    {
      name: 'Test Restaurant',
      address: '123 Test St',
      phone: '123-456-7890',
      email: 'test@example.com',
      website: 'http://example.com',
      instagram: 'http://instagram.com/test',
      description: 'A test restaurant'
    }
  }
  let(:invalid_attributes) {
    { name: nil }
  }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "GET #index" do
    it "returns a success response" do
      restaurant
      get :index
      expect(response).to be_successful
    end
  end

  describe "GET #index_by_email" do
    it "returns a success response" do
      get :index_by_email, params: { id: user.email }
      expect(response).to be_successful
    end

    it "returns a not found response if user does not exist" do
      get :index_by_email, params: { id: 'nonexistent@example.com' }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      get :show, params: { id: restaurant.to_param }
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Restaurant" do
        expect {
          post :create, params: { restaurant: valid_attributes }
        }.to change(Restaurant, :count).by(1)
      end

      it "renders a JSON response with the new restaurant" do
        post :create, params: { restaurant: valid_attributes }
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(response.location).to eq(restaurant_url(Restaurant.last))
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new restaurant" do
        post :create, params: { restaurant: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        { name: 'Updated Restaurant' }
      }

      it "updates the requested restaurant" do
        put :update, params: { id: restaurant.to_param, restaurant: new_attributes }
        restaurant.reload
        expect(restaurant.name).to eq('Updated Restaurant')
      end

      it "renders a JSON response with the restaurant" do
        put :update, params: { id: restaurant.to_param, restaurant: valid_attributes }
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the restaurant" do
        put :update, params: { id: restaurant.to_param, restaurant: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested restaurant" do
      restaurant
      expect {
        delete :destroy, params: { id: restaurant.to_param }
      }.to change(Restaurant, :count).by(-1)
    end
  end
end