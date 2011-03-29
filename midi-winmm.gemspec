# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift 'lib'
 
require 'midi-winmm'
 
Gem::Specification.new do |s|
  s.name        = "midi-winmm"
  s.version     = MIDIWinMM::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ari Russo"]
  s.email       = ["ari.russo@gmail.com"]
  s.homepage    = "http://github.com/arirusso/midi-winmm"
  s.summary     = "Realtime MIDI input and output with Ruby in Windows and Cygwin"
  s.description = "Realtime MIDI input and output with Ruby in Windows and Cygwin using the WinMM system API"
 
  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "midi-winmm"
 
  s.add_dependency "ffi", ">= 1.0"

  s.files        = Dir.glob("{lib}/**/*") + %w(LICENSE README.rdoc)
  s.require_path = 'lib'
end