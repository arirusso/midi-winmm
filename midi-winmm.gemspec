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
  s.summary     = "Interact with the Winmm MIDI API in Ruby"
  s.description = "A Ruby library for performing low level, realtime MIDI input and output in Windows.  Uses the Winmm MIDI driver interface API"
 
  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "midi-winmm"
 
  s.add_dependency "ffi"

  s.files        = Dir.glob("{lib}/**/*") + %w(LICENSE README.org)
  s.require_path = 'lib'
end