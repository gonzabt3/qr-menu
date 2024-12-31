# spec/requests/sections_controller_spec.rb
require 'rails_helper'

RSpec.describe 'Sections', type: :request do
  let(:user) { create(:user) }
  let(:restaurant) { create(:restaurant, user: user) }
  let(:menu) { create(:menu, restaurant: restaurant) }
  let(:section) { create(:section, menu: menu) }
  let(:valid_attributes) do
    {
      name: 'Test Section',
      description: 'A test section'
    }
  end
  let(:invalid_attributes) do
    { name: nil }
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:authorize).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe 'GET /restaurants/:restaurant_id/menus/:menu_id/sections' do
    it 'returns a success response' do
      get restaurant_menu_sections_path(restaurant, menu)
      expect(response).to be_successful
    end
  end

  describe 'GET /restaurants/:restaurant_id/menus/:menu_id/sections/:id' do
    it 'returns a success response' do
      get restaurant_menu_section_path(restaurant, menu, section)
      expect(response).to be_successful
    end
  end

  describe 'POST /restaurants/:restaurant_id/menus/:menu_id/sections' do
    context 'with valid params' do
      it 'creates a new Section' do
        expect do
          post restaurant_menu_sections_path(restaurant, menu), params: { section: valid_attributes }
        end.to change(Section, :count).by(1)
      end

      it 'renders a JSON response with the new section' do
        post restaurant_menu_sections_path(restaurant, menu), params: { section: valid_attributes }
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'with invalid params' do
      it 'renders a JSON response with errors for the new section' do
        post restaurant_menu_sections_path(restaurant, menu), params: { section: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end

  describe 'PUT /restaurants/:restaurant_id/menus/:menu_id/sections/:id' do
    context 'with valid params' do
      let(:new_attributes) do
        { name: 'Updated Section' }
      end

      it 'updates the requested section' do
        put restaurant_menu_section_path(restaurant, menu, section), params: { section: new_attributes }
        section.reload
        expect(section.name).to eq('Updated Section')
      end

      it 'renders a JSON response with the section' do
        put restaurant_menu_section_path(restaurant, menu, section), params: { section: valid_attributes }
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end

    context 'with invalid params' do
      it 'renders a JSON response with errors for the section' do
        put restaurant_menu_section_path(restaurant, menu, section), params: { section: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end

  describe 'DELETE /restaurants/:restaurant_id/menus/:menu_id/sections/:id' do
    it 'destroys the requested section' do
      section
      expect do
        delete restaurant_menu_section_path(restaurant, menu, section)
      end.to change(Section, :count).by(-1)
    end
  end
end
