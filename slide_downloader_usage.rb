#!/usr/bin/ruby
load 'slide_share_kit.rb'

url_hsh = {
  'nmap' => 'https://www.slideshare.net/bgasecurity/nmap-kullanm-kitap-27487242',
  'yapay zeka' => 'https://www.slideshare.net/SELENGCN/yapay-zek-ve-duygusal-zek-kullanim-farkliliklarinin-ncelenmes-teknolojk-kabul-dzey-eksennde-br-aratirma'
}

ss = SlideShareDownloader.new

strt = Time.new

url_hsh.each do |file_name, link|
  ss.download link, file_name, 'full'
end

fin = Time.new

puts "#{fin -strt} sn"
