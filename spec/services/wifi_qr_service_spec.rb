require 'rails_helper'

RSpec.describe WifiQrService, type: :service do
  describe '#payload' do
    it 'builds payload for WPA with hidden false' do
      svc = WifiQrService.new(ssid: 'MyNetwork', auth: 'WPA', password: 'secret', hidden: false)
      expect(svc.payload).to eq("WIFI:T:WPA;S:MyNetwork;P:secret;H:false;")
    end

    it 'builds payload for WEP' do
      svc = WifiQrService.new(ssid: 'Net', auth: 'WEP', password: 'abc', hidden: false)
      expect(svc.payload).to eq("WIFI:T:WEP;S:Net;P:abc;H:false;")
    end

    it 'builds payload for open network (nopass)' do
      svc = WifiQrService.new(ssid: 'OpenNet', auth: 'nopass', hidden: false)
      expect(svc.payload).to eq("WIFI:T:nopass;S:OpenNet;H:false;")
    end

    it 'normalizes WPA2 to WPA' do
      svc = WifiQrService.new(ssid: 'Net', auth: 'WPA2', password: 'pass', hidden: false)
      expect(svc.payload).to eq("WIFI:T:WPA;S:Net;P:pass;H:false;")
    end

    it 'normalizes WPA3 to WPA' do
      svc = WifiQrService.new(ssid: 'Net', auth: 'WPA3', password: 'pass', hidden: false)
      expect(svc.payload).to eq("WIFI:T:WPA;S:Net;P:pass;H:false;")
    end

    it 'raises when ssid missing' do
      expect { WifiQrService.new(ssid: '', auth: 'WPA', password: 'x').payload }.to raise_error(ArgumentError)
    end

    it 'raises when password missing for WPA' do
      expect { WifiQrService.new(ssid: 'a', auth: 'WPA', password: '') .payload }.to raise_error(ArgumentError)
    end

    it 'escapes special characters in ssid and password' do
      svc = WifiQrService.new(ssid: 'A;B,C', auth: 'WPA', password: 'p:wd;"', hidden: true)
      expect(svc.payload).to include('S:A\\;B\\,C;')
      expect(svc.payload).to include('P:p\\:wd\\;\\";')
      expect(svc.payload).to include('H:true;')
    end
  end
end
