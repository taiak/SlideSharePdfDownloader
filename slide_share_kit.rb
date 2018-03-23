# for faster thread
module ThreadHunter
  def thread_hunt
    map do |work|
      Thread.new { work.join }
    end.each(&:join)
  end
end

# add thead hunter into array class
class Array
  include ThreadHunter
end

# slide share pdf downloader
class SlideShareDownloader
  require 'curl'

  def initialize
    create_curl
    @site_pattern = '<section data-index='
    @patterns = [',', '-', '__', '/', /[\(\)]/, '`', '"', "\'", '*']
  end

  private

  # choose image quality
  def choose_size(size = 'full')
    case size
    when 'small'
      /data-small="(.*)"/
    when 'normal'
      /data-normal="(.*)"/
    else
      /data-full="(.*)"/
    end
  end

  def create_curl
    @curl = CURL.new
  end

  # get contents from url
  def get_content(url)
    @curl.get url
  end

  # seperate html to content and remove useless header
  def seperate_html(page)
    page.split(@site_pattern)[1..-1]
  end

  # seperate contents to links
  def seperate_to_links(contents, size = 'full')
    contents.map { |content| content.match(choose_size(size)).captures.first }
  end

  def download_image(link, name, number)
    file = "#{name}_#{number}.jpg"
    return false if exist_file?(file)
    system "curl #{link} >'#{file}' 2>/dev/null"
  end

  # download images from links

  def download_images(name, links)
    links.each_with_index.map do |link, i|
      Thread.new { download_image link, name, i }
    end.thread_hunt
  end

  # symbolize all jpg file start with name
  def all_images_name(name)
    "#{name}_*.jpg"
  end

  # convert images to pdf
  def image_to_pdf(name)
    pdf_name = "#{name}.pdf"

    if exist_file?(pdf_name)
      puts 'Canceling to converting...'
      return false
    end

    puts   "Converting to pdf for #{name}..."
    system "convert #{all_images_name name} '#{pdf_name}'"
    true
  end

  # OPTIMIZE: add support for multi platform
  def optimize_images(name)
    puts   "Images optimization start for #{name}.."
    system "jpegoptim #{all_images_name name} >/dev/null"
  end

  # remove all image file
  def rm_jpgs_start_with(name)
    Dir.glob(all_images_name(name)).each { |f| File.delete(f) }
  end

  # make useful and uniq name from pdf_name and size
  def make_file_name(pdf_name, size = '')
    name = pdf_name.dup
    name.gsub!(/[\s]/, '_')
    @patterns.each { |pattern| name.gsub!(pattern, '') }
    name + '_' + size
  end

  # seperate links and get links
  def get_links(url, size = 'full')
    page = get_content url
    contents = seperate_html page
    seperate_to_links contents, size
  end

  def process_images(pdf_name)
    optimize_images pdf_name
    image_to_pdf pdf_name
    rm_jpgs_start_with pdf_name
  end

  def exist_file?(name)
    if File.file?(name)
      puts "#{name} found!"
      true
    else
      false
    end
  end

  public

  # download single file
  def download(url, pdf_name, size = 'full')
    pdf_name = make_file_name pdf_name, size

    return false if exist_file? "#{pdf_name}.pdf"

    puts "#{pdf_name} downloading..."
    links = get_links url, size

    download_images pdf_name, links

    process_images pdf_name
  end

  # download url's from hash info
  def parallel_download(url_hsh, size = 'full')
    url_hsh.map do |name, link|
      Thread.new { download(link, name, size) }
    end.thread_hunt
  end
end
