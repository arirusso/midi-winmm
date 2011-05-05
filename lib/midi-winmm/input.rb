#!/usr/bin/env ruby
module MIDIWinMM
  
  #
  # Input device class for the WinMM driver interface 
  #
  class Input
    
    include Device
    
    BufferSize = 2048
    
    # initializes this device
    def enable(options = {}, &block)
      init_input_buffer
      handle_ptr = FFI::MemoryPointer.new(FFI.type_size(:int))
      @buffer = []
      @event_callback = get_event_callback
      
      Map.winmm_func(:midiInOpen, handle_ptr, @id, @event_callback, 0, Device::WinmmCallbackFlag)
      
      @handle = handle_ptr.read_int
      
      Map.winmm_func(:midiInPrepareHeader, @handle, @header.pointer, @header.size)      
      Map.winmm_func(:midiInAddBuffer, @handle, @header.pointer, @header.size)
      Map.winmm_func(:midiInStart, @handle)

      spawn_listener
      @enabled = true
      
      unless block.nil?
        begin
          block.call(self)
        ensure
          close
        end
      else
        self
      end
      
    end
    alias_method :start, :enable
    alias_method :open, :enable
    
    #
    # returns an array of MIDI event hashes as such:
    # [ 
    #   { :data => [144, 90, 100], :timestamp => 1024 },
    #   { :data => [128, 90, 100], :timestamp => 1100 },
    #   { :data => [146, 60, 120], :timestamp => 1200 }
    # ]
    #
    # message data is an array of Numeric bytes
    #
    def gets
      @listener.join
      msgs = @buffer.dup
      @buffer.clear
      spawn_listener
      msgs
    end
    
    # same as gets but returns message data as string of hex digits as such:
    # [ 
    #   { :data => "904060", :timestamp => 904 },
    #   { :data => "804060", :timestamp => 1150 },
    #   { :data => "90447F", :timestamp => 1300 }
    # ]
    #
    #
    def gets_bytestr
      msgs = gets
      msgs.each { |msg| msg[:data] = msg[:data].map { |b| s = b.to_s(16).upcase; b < 16 ? s = "0" + s : s; s }.join }
      msgs	
    end
    
    # close the device
    def close
      Thread.kill(@listener)
      Map.winmm_func(:midiInUnprepareHeader, @handle, @header.pointer, @header.size)
      Map.winmm_func(:midiInStop, @handle)
      Map.winmm_func(:midiInClose, @handle)
      @enabled = false
    end
    
    def self.first
      Device::first(:input)
    end

    def self.last
      Device::last(:input)
    end
    
    def self.all
      Device.all_by_type[:input]
    end
        
    private
    
    # launch a background Thread that collects messages
    def spawn_listener
      @listener = Thread.fork do
        while @buffer.empty? do
          sleep(0.1)
        end
      end
    end
    
    # prepare the header struct where input event information is held
    def init_input_buffer
      @header = Map::MIDIHdr.new
      @header.write_data(Input::BufferSize)
      @header[:dwBytesRecorded] = 0
      @header[:dwFlags] = 0
      @header[:dwUser] = 0
      @header[:dwBufferLength] = Input::BufferSize
    end
    
    # returns a Proc that is called when the device receives a message
    def get_event_callback
      Proc.new do |hMidiIn,wMsg,dwInstance,dwParam1,dwParam2|
        msg_type = Map::CallbackMessageTypes[wMsg] || ''
        case msg_type
          when :input_data then 
        	msg = [{ :data => message_to_hex(dwParam1), :timestamp => dwParam2 }]
        	@buffer += msg
          when :input_long_data then

        	@receiving_sysex = true
			data = @header[:lpData].read_string(Input::BufferSize).gsub(/ /, '')
			unless data.eql?("")
			  str = data.unpack(("C" * (data.length-1)))
			  msg = [{ :data => str, :timestamp => dwParam2 }]
        	  @buffer += msg
        	end
      		
        end
      end
    end
    
  end
  
end
