#!/usr/bin/ruby
load 'slide_share_kit.rb'

url_hsh_example = {
  'nmap' => 'https://www.slideshare.net/bgasecurity/nmap-kullanm-kitap-27487242',
  'yapay zeka' => 'https://www.slideshare.net/SELENGCN/yapay-zek-ve-duygusal-zek-kullanim-farkliliklarinin-ncelenmes-teknolojk-kabul-dzey-eksennde-br-aratirma'
}

ss = SlideShareDownloader.new

# download single file
# url_hsh.each do |file_name, link|
#   ss.download link, file_name, 'full', false
# end


# download paralel
ss.parallel_download url_hsh, 'full'


