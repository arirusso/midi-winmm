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
      @event_callback = event_callback
      
      Map.winmm_func(:midiInOpen, handle_ptr, @id, @event_callback, @header[:lpData].address, Device::WinmmCallbackFlag)
      
      @handle = handle_ptr.read_int

      Map.winmm_func(:midiInPrepareHeader, @handle, @header.pointer, @header.size)      
      Map.winmm_func(:midiInAddBuffer, @handle, @header.pointer, @header.size)
      Map.winmm_func(:midiInStart, @handle)

      @enabled = true

            unless block.nil?
      begin
          block.call(self)
        ensure
          close
        end
      end
      
    end
    
    #
    # returns an array of MIDI event hashes as such:
    # [ 
    #   { :data => "904040", :timestamp => 1024 },
    #   { :data => "804040", :timestamp => 1100 },
    #   { :data => "90607F", :timestamp => 1200 }
    # ]
    #
    def read_buffer
      result = nil
      messages = @header.data.split(',')
      message = messages.shift
      unless message.nil?
        timestamp, data = message.split('#')
        unless timestamp.nil? || data.nil? 
          result = { :data => message_to_hex(data.to_i), :timestamp => timestamp.to_i }
          new_buffer = messages.join(',')
          @header.write_data(BufferSize, new_buffer)
          p result
        end
      end
      result
    end
    
    alias_method :read, :read_buffer
    
    # close the device
    def close
      reset
      Map.winmm_func(:midiInUnprepareHeader, @handle, @input_buffer, hdr_size)
      Map.winmm_func(:midiInStop, @handle)
      Map.winmm_func(:midiInClose, @handle)
      @enabled = false
    end
    
    # reset the device
    def reset
      Map.winmm_func(:midiInReset, @handle)
    end
    
    private
    
    # prepare the header struct where input event information is held
    def init_input_buffer
      @header = Map::MIDIHdr.new
      @header.write_data(BufferSize)
      @header[:dwBytesRecorded] = 0
      @header[:dwFlags] = 0
      @header[:dwUser] = 0
    end
   
    # this is called when the device receives a message
    def event_callback
      Proc.new do |hMidiIn,wMsg,dwInstance,dwParam1,dwParam2|
        msg_type = Map::CallbackMessageTypes[wMsg] || ''
        if [:input_data, :input_long_data].include?(msg_type)
          # IN PROGRESS
          if msg_type.eql?(:input_long_data)
            @receiving_sysex = true
            p (dwParam1 << 24)
          end     
          msg = "#{dwParam2.to_s}##{dwParam1.to_s}"
          existing_buffer = @header.data
          msg = (existing_buffer.length.zero? ? "#{existing_buffer}," : '') + msg 
          @header.write_data(BufferSize, msg)
        end
        nil
      end
    end
    
  end
  
end