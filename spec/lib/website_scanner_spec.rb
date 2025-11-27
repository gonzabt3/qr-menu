require 'rails_helper'
require 'website_scanner'

RSpec.describe WebsiteScanner do
  let(:url) { 'http://example.com' }
  let(:scanner) { WebsiteScanner.new(url) }

  describe '#initialize' do
    it 'normalizes url without protocol' do
      scanner = WebsiteScanner.new('example.com')
      expect(scanner.url).to eq('http://example.com')
    end

    it 'keeps url with protocol' do
      scanner = WebsiteScanner.new('https://example.com')
      expect(scanner.url).to eq('https://example.com')
    end
  end

  describe '#scan' do
    let(:html_content) do
      <<~HTML
        <html>
          <body>
            <a href="/menu">Menu</a>
            <a href="/carta.pdf">Carta</a>
            <a href="https://instagram.com/testrestaurant">Instagram</a>
            <a href="javascript:void(0)">Link</a>
          </body>
        </html>
      HTML
    end

    before do
      stub_request(:get, url)
        .to_return(status: 200, body: html_content, headers: { 'Content-Type' => 'text/html' })
    end

    it 'scans website and finds menu links' do
      result = scanner.scan
      expect(result[:menu_urls]).to be_an(Array)
      expect(result[:menu_urls]).to include('http://example.com/menu')
    end

    it 'finds instagram link' do
      result = scanner.scan
      expect(result[:instagram]).to eq('https://instagram.com/testrestaurant')
    end

    it 'filters out javascript links' do
      result = scanner.scan
      menu_urls = result[:menu_urls]
      expect(menu_urls).not_to include('javascript:void(0)')
    end

    it 'finds PDF menu links' do
      result = scanner.scan
      expect(result[:menu_urls]).to include('http://example.com/carta.pdf')
    end

    context 'when no menu links are found but body mentions menu' do
      let(:html_content) do
        <<~HTML
          <html>
            <body>
              <p>Nuestro menú es delicioso</p>
            </body>
          </html>
        HTML
      end

      it 'includes the main url as a menu link' do
        result = scanner.scan
        expect(result[:menu_urls]).to include(url)
      end
    end

    context 'when website fetch fails' do
      before do
        stub_request(:get, url).to_return(status: 404)
      end

      it 'raises an error' do
        expect { scanner.scan }.to raise_error(/Failed to fetch/)
      end
    end
  end
end
