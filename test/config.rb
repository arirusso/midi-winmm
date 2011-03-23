module TestHelper::Config
  
  include MIDIWinMM
  
  # adjust these constants to suit your hardware configuration 
  # before running tests
  
  NumDevices = 4 # this is the total number of MIDI devices that are connected to your system
  TestInput = Device.first(:input) # this is the device you wish to use to test input
  TestOutput = Device.first(:output) # likewise for output
  
end