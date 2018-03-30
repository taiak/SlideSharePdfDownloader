# for faster thread
module ThreadHunter
  def thread_hunt
    self.map do |work|
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
  require 'prawn'
  require 'fastimage'
  require 'logger'

  def initialize
    create_curl
    @site_pattern = '<section data-index='
    @patterns = [',', '-', '__', '/', /[\(\)]/, '`', '"', "\'", '*']
    @log = Logger.new('log.txt')
    @log.level = Logger::INFO
  end

  # download single file
  def download(url, pdf_name, size = 'full', parallel_download: true)
    pdf_name = make_file_name pdf_name, size

    return false if exist_file? "#{pdf_name}.pdf"

    @log.info "#{pdf_name} downloading..."
    links = get_links url, size

    if parallel_download
      download_images_parallel pdf_name, links
    else
      download_images pdf_name, links
    end
    
    process_images pdf_name
  end

  # download url's from hash info
  # ram usage controlless
  # TODO: before activate it use thread splitter and set thread limit
  # def parallel_download(url_hsh, size = 'full', parallel = false)
  #   url_hsh.map do |name, link|
  #     Thread.new { download(link, name, size, parallel) }
  #   end.thread_hunt
  # end

  private
  # choose image quality
  def choose_size(size = 'full')
    case size
    when 'small'
      /data-small="([^\"]*)"/
    when 'normal'
      /data-normal="([^\"]*)"/
    else
      /data-full="([^\"]*)"/
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
    begin
      contents.map { |content| content.match(choose_size(size)).captures.first }
    rescue NoMethodError
      @log.Error "seperate error!"
    end
  end

  # control image file format. 
  # if file format unsupported download it again with os supported
  def control_images(file, link)
    @log.info "#{file} controlling..."
    unless FastImage.type(file)
      @log.error "#{file} unsupported!!!"
      @log.info  "#{file} downloading with os support(curl)..."
      system "curl #{link} > '#{file}' 2>/dev/null" 
    end
    @log.info "#{file} controlled..."
  end

  def download_image(link, name, number)
    f_name = "#{name}_#{number}.jpg"
    @log.info "#{f_name} downloading..."
    unless exist_file?(f_name)
      @log.info "Download start for #{f_name}..."
      @curl.save(link, f_name)
      @log.info "Download finish for #{f_name}..."
    end
    control_images f_name, link
  end

  # download images from links parallel
  def download_images_parallel(name, links)
    @log.info "Start parallel downloading for #{name}..."
    
    links.each_with_index.map do |link, i|
      Thread.new { download_image link, name, i }
    end.thread_hunt

    @log.info "Parallel downloading finish for #{name}..."
  end

  # download images from links
  def download_images(name, links)
    @log.info "Start downloading for #{name}..."

    links.each_with_index { |link, i| download_image link, name, i }

    @log.info "Downloading finish for #{name}..."
  end

  def sorted_all_images_name(name)
    Dir.glob("#{name}_*.jpg").sort_by { |s| s[/\d+/].to_i }
  end

  # symbolize all jpg file start with name
  def all_images_name(name)
    "#{name}_*.jpg"
  end

  # OPTIMIZE: add support for multi platform
  def optimize_images(name)
    @log.info "Images optimization start for #{name}.."
    system "jpegoptim #{all_images_name name} >/dev/null"
    @log.info "Images optimization finish for #{name}.."
  end

  # remove all image file
  def rm_jpgs_start_with(name)
    @log.info "Removing #{name}'s jpg file..."
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

  def jpeg_to_pdf_convert(name)
    @log.info "Pdf converting start for #{name}..."
    image_names = sorted_all_images_name(name)
    return false unless image_names

    size = FastImage.size image_names.first

    begin
      Prawn::Document.generate("#{name}.pdf", :page_size => size, :margin => 0) do
        image image_names.first, :at => [0, size[-1]]
        image_names[1..-1].each do |img|
          start_new_page
          image img, :at => [0, size[-1]]
        end
      end
      @log.info "Pdf converting finish for #{name}..."
      true
    rescue Exception
      @log.error "Pdf Converting for #{name}!"
      false
    end
  end

  def process_images(pdf_name)
    @log.info "Process start for #{pdf_name}..."
    optimize_images pdf_name
    success = jpeg_to_pdf_convert pdf_name
    rm_jpgs_start_with pdf_name if success
    @log.info "Process finish for #{pdf_name}..."
  end

  def exist_file?(name)
    if File.file?(name)
      @log.info "#{name} found!"
      true
    else
      false
    end
  end
end
