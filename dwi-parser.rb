require 'pry'

class StepDWI

  def self.parse(file_path)
    lines = self.get_lines(file_path)
    usable_lines = self.select_usable_lines(lines)
    self.convert_dwi_to_hash(usable_lines)
  end

  def self.get_lines(file_path)
    File.foreach(file_path).map do |line|
      if line[0] == '#'
        line_arr_raw = line.strip.split(/[#:;]/)
        line_arr = line_arr_raw.reject(&:empty?)
      end
    end.compact
  end

  def self.select_usable_lines(lines)
    usable = ['title', 'artist', 'bpm', 'gap', 'changebpm', 'freeze', 'single']
    lines.select do |line|
      usable.include?(line[0].downcase)
    end
  end

  def self.convert_dwi_to_hash(usable_lines)
    song_hash = self.convert_dwi_strings(usable_lines, {})
    # song_hash = self.convert_dwi_stops(usable_lines, song_hash)
    # song_hash = self.convert_dwi_bpms(usable_lines, song_hash)
    # self.convert_dwi_notes(usable_lines, song_hash)
  end

  def self.convert_dwi_strings(usable_lines, working_hash)
    working_hash[:title] = self.convert_title(usable_lines)
    working_hash[:subtitle] = ''
    working_hash[:artist] = self.convert_artist(usable_lines)
    working_hash[:offset] = self.convert_gap(usable_lines)
    working_hash
  end

  def self.convert_title(usable_lines)
    title_arr = usable_lines.find do |line|
      line[0].downcase === 'title'
    end

    if title_arr
      title_arr[1]
    else
      ''
    end
  end

  def self.convert_artist(usable_lines)
    artist_arr = usable_lines.find do |line|
      line[0].downcase === 'artist'
    end

    if artist_arr
      artist_arr[1]
    else
      ''
    end
  end

  def self.convert_gap(usable_lines)
    gap_arr = usable_lines.find do |line|
      line[0].downcase === 'gap'
    end

    if gap_arr
      gap_arr[1]
    else
      '0'
    end
  end

  def self.convert_dwi_stops

  end

end

Pry.start
