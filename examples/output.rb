dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift dir + '/../lib'

require 'midi-winmm'

# this program selects the first midi output and sends some arpeggiated chords to it

notes = [36, 40, 43] # C E G
octaves = 6
duration = 0.1

# MIDIWinMM::Device.all.to_s will list your midi outputs
  
output = MIDIWinMM::Device.first(:output)
output.enable do |output|

  5.times do |i|
    notes.each do |note|
      oct = i * 12
      output.output_message(0x90, note + oct, 100)
      sleep(duration)
      output.output_message(0x80, note + oct, 100)
    end
  end
  
end