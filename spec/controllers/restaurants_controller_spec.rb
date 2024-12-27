 #spec/requests/restaurants_controller_spec.rb
require 'rails_helper'

RSpec.describe "Restaurants", type: :request do
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
    allow_any_instance_of(ApplicationController).to receive(:authorize).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end


  describe "GET /restaurants" do
    it "returns a success response" do
      restaurant
      get restaurants_path
      expect(response).to be_successful
    end
  end

  describe "GET /users/:email/restaurants" do
    it "returns a success response" do
      get restaurants_user_path(user.email)
      expect(response).to be_successful
    end

    it "returns a not found response if user does not exist" do
      get restaurants_user_path('nonexistent@example.com')
      expect(response).to have_http_status(:not_found)
    end
  end

   describe "GET /restaurants/:id" do
    let(:restaurant1) { create(:restaurant, user: user) }
     it "returns a success response" do
       byebug
       get restaurant_path(restaurant1)
       expect(response).to be_successful
     end
   end

   describe "POST /restaurants" do
     context "with valid params" do
       it "creates a new Restaurant" do
         expect {
           post restaurants_path, params: { restaurant: valid_attributes }
         }.to change(Restaurant, :count).by(1)
       end

       it "renders a JSON response with the new restaurant" do
         post restaurants_path, params: { restaurant: valid_attributes }
         expect(response).to have_http_status(:created)
         expect(response.content_type).to eq('application/json; charset=utf-8')
       end
     end

     context "with invalid params" do
       it "renders a JSON response with errors for the new restaurant" do
         post restaurants_path, params: { restaurant: invalid_attributes }
         expect(response).to have_http_status(:unprocessable_entity)
         expect(response.content_type).to eq('application/json; charset=utf-8')
       end
     end
   end

   describe "PUT /restaurants/:id" do
     context "with valid params" do
       let(:new_attributes) {
         { name: 'Updated Restaurant' }
       }

       it "updates the requested restaurant" do
         put restaurant_path(restaurant), params: { restaurant: new_attributes }
         restaurant.reload
         expect(restaurant.name).to eq('Updated Restaurant')
       end

       it "renders a JSON response with the restaurant" do
         put restaurant_path(restaurant), params: { restaurant: valid_attributes }
         expect(response).to have_http_status(:ok)
         expect(response.content_type).to eq('application/json; charset=utf-8')
       end
     end

     context "with invalid params" do
       it "renders a JSON response with errors for the restaurant" do
         put restaurant_path(restaurant), params: { restaurant: invalid_attributes }
         expect(response).to have_http_status(:unprocessable_entity)
         expect(response.content_type).to eq('application/json; charset=utf-8')
       end
     end
   end

   describe "DELETE /restaurants/:id" do
     it "destroys the requested restaurant" do
       restaurant
       expect {
         delete restaurant_path(restaurant)
       }.to change(Restaurant, :count).by(-1)
     end
   end
end