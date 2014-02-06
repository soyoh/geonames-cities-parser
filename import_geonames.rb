# Small script to grab and export cities from Geoname
#
# Based on Rails gem: https://github.com/kmmndr/geonames_dump/blob/develop/lib/tasks/import.rake
#
# author: Alejanro Hoyos <alejandro@dezarrolla.com>

require 'json'
require_relative 'helpers'


EXPORT_FOLDER = './exports'
COL_NAMES = [
  :geonameid, :name, :asciiname, :alternatenames, :latitude, :longitude,
  :feature_class, :feature_code, :country_code, :cc2, :admin1_code,
  :admin2_code, :admin3_code, :admin4_code, :population, :elevation,
  :dem, :timezone, :modification
]


def prepare_file(file_fd, col_names, options = {})

  file_size = file_fd.stat.size
  file_name = options[:file_name] || "file_#{rand(0..1000)}.sql"

  primary_key = :geonameid
  progress_bar = ProgressBar.create(:title => file_name, :total => file_size, :format => '%a |%b>%i| %p%% %t')


  lines_linked = {}
  counter = 0

  puts "preparing the hash..."
  # Generates line
  file_fd.each_line do |line|
    # skip comments
    next if line.start_with?('#')

    # link attributes in each line
    attributes = {}

    line.strip.split("\t").each_with_index do |col_value, idx|
      col = col_names[idx]
      # skip leading and trailing whitespace
      col_value.strip!

      attributes[col] = col_value
    end

    lines_linked[counter] = attributes
    counter += 1

    # move progress bar
    progress_bar.progress = file_fd.pos
  end

  puts " ... now writing to file... #{lines_linked.size} records"
  File.open("#{EXPORT_FOLDER}/#{file_name}", 'w') do |file|
    file.write(lines_linked.to_json)
  end

  puts "... Done!!"
end


# Solo queremos ciudades con hasta > 5000 habitantes
%w[15000 5000 1000].each do |population|
  txt_file = get_or_download("http://download.geonames.org/export/dump/cities#{population}.zip")

  File.open(txt_file) do |f|
    prepare_file(f, COL_NAMES, :file_name => "#{population}.json")
  end
end