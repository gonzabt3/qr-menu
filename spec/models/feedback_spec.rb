require 'rails_helper'

RSpec.describe Feedback, type: :model do
  describe 'validations' do
    it 'is valid with a message' do
      feedback = build(:feedback, message: 'Test message')
      expect(feedback).to be_valid
    end

    it 'is invalid without a message' do
      feedback = build(:feedback, message: nil)
      expect(feedback).not_to be_valid
      expect(feedback.errors[:message]).to include("can't be blank")
    end

    it 'is invalid with an empty message' do
      feedback = build(:feedback, message: '')
      expect(feedback).not_to be_valid
      expect(feedback.errors[:message]).to include("can't be blank")
    end

    it 'is invalid with a message longer than 2000 characters' do
      feedback = build(:feedback, message: 'a' * 2001)
      expect(feedback).not_to be_valid
      expect(feedback.errors[:message]).to include('is too long (maximum is 2000 characters)')
    end

    it 'is valid with a message of exactly 2000 characters' do
      feedback = build(:feedback, message: 'a' * 2000)
      expect(feedback).to be_valid
    end
  end
end
