
require 'net/http'
require 'ruby-progressbar'
require 'zip/zipfilesystem'

def get_or_download(url, options = {})
  filename = File.basename(url)
  unzip = File.extname(filename) == '.zip'
  txt_filename = unzip ? "#{File.basename(filename, '.zip')}.txt" : filename
  txt_file_in_cache = File.join('./zips', options[:txt_file] || txt_filename)
  zip_file_in_cache = File.join('./zips', filename)

  unless File::exist?(txt_file_in_cache)
    puts 'file doesn\'t exists'
    if unzip
      download(url, zip_file_in_cache)
      # unzip_file(zip_file_in_cache, './zips')

      puts "unzipping #{zip_file_in_cache}"
      # Zip::File.open(file) do |zip_file|
      Zip::ZipFile.open(zip_file_in_cache) do |zip_file|
        zip_file.each do |f|
          f_path = File.join('./zips', f.name)
          FileUtils.mkdir_p(File.dirname(f_path))
          zip_file.extract(f, f_path) unless File.exist?(f_path)
        end
      end


    else
      download(url, txt_file_in_cache)
    end
  else
    puts "file already exists : #{txt_file_in_cache}"
  end

  ret = (File::exist?(txt_file_in_cache) ? txt_file_in_cache : nil)
end

def download(url, output)
  File.open(output, "wb") do |file|
    # body = fetch(url)

    puts "Fetching #{url}"
    url = URI.parse(url)
    req = Net::HTTP::Get.new(url.path)
    res = Net::HTTP.start(url.host, url.port) {|http| http.request(req)}
    body = res.body

    puts "Writing #{url} to #{output}"
    file.write(body)
  end
end