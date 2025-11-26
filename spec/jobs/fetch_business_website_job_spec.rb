require 'rails_helper'

RSpec.describe FetchBusinessWebsiteJob, type: :job do
  let(:business) { create(:business, website: 'http://example.com') }

  describe '#perform' do
    context 'when business has a website' do
      let(:scan_result) do
        {
          menu_urls: ['http://example.com/menu'],
          instagram: 'https://instagram.com/test'
        }
      end

      before do
        allow_any_instance_of(WebsiteScanner).to receive(:scan).and_return(scan_result)
      end

      it 'scans the website and updates business' do
        described_class.new.perform(business.id)
        business.reload

        expect(business.status).to eq('scanned')
        expect(business.menu_urls).to eq(['http://example.com/menu'])
        expect(business.instagram).to eq('https://instagram.com/test')
        expect(business.has_menu).to be true
      end

      it 'preserves existing instagram if scanner returns nil' do
        business.update(instagram: 'existing_instagram')
        scan_result[:instagram] = nil
        
        described_class.new.perform(business.id)
        business.reload

        expect(business.instagram).to eq('existing_instagram')
      end
    end

    context 'when business has no website' do
      let(:business) { create(:business, website: nil) }

      it 'marks business as failed' do
        described_class.new.perform(business.id)
        business.reload

        expect(business.status).to eq('failed')
        expect(business.raw_response['error']).to eq('no website')
      end
    end

    context 'when scanner raises an error' do
      before do
        allow_any_instance_of(WebsiteScanner).to receive(:scan).and_raise(StandardError.new('Network error'))
      end

      it 'marks business as failed and stores error' do
        described_class.new.perform(business.id)
        business.reload

        expect(business.status).to eq('failed')
        expect(business.raw_response['error']).to eq('Network error')
      end
    end

    context 'when business does not exist' do
      it 'does not raise error' do
        expect { described_class.new.perform(99999) }.not_to raise_error
      end
    end
  end
end
