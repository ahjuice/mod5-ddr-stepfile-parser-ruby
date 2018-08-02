require 'pry'
require 'json'

class StepDWI
  @@ARROW_MAP = {
    "0" => "0000",
    "1" => "1100",
    "2" => "0100",
    "3" => "0101",
    "4" => "1000",
    "6" => "0001",
    "7" => "1010",
    "8" => "0010",
    "9" => "0011",
    "A" => "0110",
    "B" => "1001",
  }

  def self.parse(file_path)
    lines = self.get_lines(file_path)
    usable_lines = self.select_usable_lines(lines)
    step_hash = self.convert_dwi_to_hash(usable_lines)

    File.open("output.json","w") do |f|
      f.write(JSON.pretty_generate(step_hash))
    end
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
    song_hash = self.convert_dwi_stops(usable_lines, song_hash)
    song_hash = self.convert_dwi_bpms(usable_lines, song_hash)
    song_hash = self.convert_dwi_notes(usable_lines, song_hash)
    song_hash
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
      line[0].downcase == 'title'
    end

    if title_arr
      title_arr[1]
    else
      ''
    end
  end

  def self.convert_artist(usable_lines)
    artist_arr = usable_lines.find do |line|
      line[0].downcase == 'artist'
    end

    if artist_arr
      artist_arr[1]
    else
      ''
    end
  end

  def self.convert_gap(usable_lines)
    gap_arr = usable_lines.find do |line|
      line[0].downcase == 'gap'
    end

    if gap_arr
      gap_arr[1]
    else
      '0'
    end
  end

  def self.convert_dwi_stops(usable_lines, working_hash)
    stops_arr = usable_lines.find do |line|
      line[0].downcase == 'freeze'
    end

    if stops_arr
      working_hash[:stops] = {}
      stops = stops_arr[1].split(',')
      stops.each do |stop|
        beat_duration = stop.split('=')
        working_hash[:stops][beat_duration[0]] = beat_duration[1]
      end
    end

    working_hash
  end

  def self.convert_dwi_bpms(usable_lines, working_hash)
    initial_bpm_arr = usable_lines.find do |line|
      line[0].downcase == 'bpm'
    end

    working_hash[:bpms] = {"0" => initial_bpm_arr[1]}

    bpm_change_arr = usable_lines.find do |line|
      line[0].downcase == 'changebpm'
    end

    if bpm_change_arr
      bpms = bpm_change_arr[1].split(',')
      bpms.each do |bpm|
        beat_new_bpm = bpm.split('=')
        working_hash[:bpms][beat_new_bpm[0]] = beat_new_bpm[1]
      end
    end

    working_hash
  end

  def self.convert_dwi_notes(usable_lines, song_hash)
    notesArr = []

    if self.convert_beginner_notes(usable_lines)
      notesArr.push(self.convert_beginner_notes(usable_lines))
    end

    song_hash[:notes] = notesArr
    song_hash
  end

  def self.process_note_str(note_str)
    # should return an array of measure arrays
    measures = []

    start_index = 0
    while start_index < note_str.length do
      end_index = start_index + 7
      note_str_range = note_str[start_index..end_index]

      if note_str_range.length < 8
        diff = 8 - note_str_range.length
        padding = "0" * diff
        note_str_range += padding
      end

      measures.push(self.build_measure_arr(note_str_range))

      start_index += 8
    end

    measures
  end

  def self.build_measure_arr(str)
    step_arr = str.split("")

    step_arr.map do |step|
      @@ARROW_MAP[step]
    end
  end

  def self.convert_beginner_notes(usable_lines)
    beginner_notes_arr = usable_lines.find do |line|
      line[0].downcase == 'single' && line[1].downcase == 'beginner'
    end

    beginner_notes_hash = {}

    if beginner_notes_arr
      beginner_notes_hash[:notesType] = "dance-single"
      beginner_notes_hash[:description] = "Beginner"
      beginner_notes_hash[:difficultyClass] = "beginner"
      beginner_notes_hash[:difficultyMeter] = beginner_notes_arr[2]
      beginner_notes_hash[:noteData] = self.process_note_str(beginner_notes_arr[3])
    else
      beginner_notes_hash = nil
    end

    beginner_notes_hash
  end
end

Pry.start
