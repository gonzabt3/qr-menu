require 'rails_helper'

RSpec.describe AiClient, type: :service do
  describe '.instance' do
    context 'when AI_PROVIDER is deepseek' do
      before do
        allow(ENV).to receive(:fetch).with('AI_PROVIDER', 'deepseek').and_return('deepseek')
        allow(ENV).to receive(:[]).with('DEEPSEEK_API_KEY').and_return('test-key')
      end

      it 'returns a Deepseek client' do
        expect(AiClient.instance).to be_a(AiClient::Deepseek)
      end
    end

    context 'when AI_PROVIDER is openai' do
      before do
        allow(ENV).to receive(:fetch).with('AI_PROVIDER', 'deepseek').and_return('openai')
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test-key')
      end

      it 'returns an OpenAI client' do
        expect(AiClient.instance).to be_a(AiClient::Openai)
      end
    end

    context 'when AI_PROVIDER is invalid' do
      before do
        allow(ENV).to receive(:fetch).with('AI_PROVIDER', 'deepseek').and_return('invalid')
      end

      it 'raises ConfigurationError' do
        expect {
          AiClient.instance
        }.to raise_error(AiClient::ConfigurationError, /Unknown AI_PROVIDER/)
      end
    end
  end

  describe 'base class methods' do
    let(:client) { AiClient.new }

    describe '#embed' do
      it 'raises NotImplementedError' do
        expect {
          client.embed('test')
        }.to raise_error(NotImplementedError)
      end
    end

    describe '#complete' do
      it 'raises NotImplementedError' do
        expect {
          client.complete('test')
        }.to raise_error(NotImplementedError)
      end
    end
  end
end
