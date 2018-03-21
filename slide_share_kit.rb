# slide share pdf downloader
class SlideShareDownloader
  require 'progressbar'
  require 'curl'

  def initialize
    create_curl
    set_site_pattern
    @patterns = [',', '-', '__', '/', /[\(\)]/, '`', '"', "\'", '*']
  end

  def set_site_pattern
    @site_pattern = '<section data-index='
  end

  # choose image quality
  def choose_size(size = 'full')
    case size
    when 'small'
      /data-small="(.*)"/
    when 'normal'
      /data-normal="(.*)"/
    when 'full'
      /data-full="(.*)"/
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

  # download images from links
  def download_images_with_pb(name, links)
    if File.file?(add_ext(name))
      puts "#{add_ext name} found!"
      return false
    end

    pb = ProgressBar.create(title: name[0..20],
                            total: links.size,
                            format: '%t |%a: %B %P%% |')

    links.each_with_index do |link, i|
      pb.increment
      file = "#{name}_#{i}.jpg"
      next if File.file?(file)
      system "curl #{link} >'#{file}' 2>/dev/null"
    end
    true
  end

  def download_images(name, links)
    if File.file?(add_ext(name))
      puts "#{add_ext name} found!"
      return false
    end

    links.each_with_index do |link, i|
      file = "#{name}_#{i}.jpg"
      next if File.file?(file)
      system "curl #{link} >'#{file}' 2>/dev/null"
    end
    true
  end

  # add extension to string
  def add_ext(str, ext = 'pdf')
    "#{str}.#{ext}"
  end

  # symbolize all jpg file start with name
  def images_name(name)
    "#{name}_*.jpg"
  end

  # convert images to pdf
  def image_to_pdf(pdf_name)
    name = add_ext pdf_name, 'pdf'

    if File.file?(name)
      puts "Warning: #{name} still exist..."
      puts 'Canceling to converting...'
      return false
    end

    puts   "Converting to pdf for #{pdf_name}..."
    system "convert #{images_name pdf_name} '#{name}'"
    true
  end

  # OPTIMIZE: make multi platform
  def optimize_images(name)
    puts "Images optimization start for #{name}.."
    system "jpegoptim #{images_name name} >/dev/null"
  end

  # remove all image file
  def rm_jpgs_start_with(name)
    Dir.glob(images_name(name)).each { |f| File.delete(f) }
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

  # is file exist? only for file
  def file?(name)
    File.file?(name) ? true : false
  end

  def process_images(pdf_name)
    optimize_images pdf_name
    image_to_pdf pdf_name
    rm_jpgs_start_with pdf_name
  end

  # download single file
  def download(url, pdf_name, size = 'full', progressbar = true)
    pdf_name = make_file_name pdf_name, size

    if file?(add_ext(pdf_name, 'pdf'))
      puts "#{pdf_name} found!"
      return false
    end
    puts "#{pdf_name} downloading..."
    links = get_links url, size
    if progressbar
      download_images_with_pb pdf_name, links
    else
      download_images pdf_name, links
    end

    process_images pdf_name
    true
  end

  # download url's from hash info
  def parallel_download(url_hsh, size = 'full')
    threads = url_hsh.collect do |name, link|
      Thread.new { download(link, name, size, false) }
    end
    threads.map { |work| Thread.new { work.join } }.each(&:join)
  end
end