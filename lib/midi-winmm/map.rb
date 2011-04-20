#!/usr/bin/env ruby
module MIDIWinMM
  
  #
  # Module containing C function and struct binding for the WinMM 
  # driver interface library
  #
  module Map
    
    extend FFI::Library
    ffi_lib 'Winmm'
    ffi_convention :stdcall
    
    HeaderFlags = {
      0x00000001 => :done,
      0x00000002 => :prepared,
      0x00000004 => :inqueue,
      0x00000008 => :isstream
    }
    
    CallbackMessageTypes = {
      0x3C1 => :input_open,
      0x3C2 => :input_close,
      0x3C3 => :input_data,        
      0x3C4 => :input_long_data,
      0x3C5 => :input_error,
      0x3C6 => :input_long_error,
      0x3C7 => :output_open, 
      0x3C8 => :output_close,
      0x3C9 => :output_data,
      0x3CC => :output_more_data
    }
    
    Errors = {
      1 => "Unspecified",
      2 => "Bad Device ID",
      3 => "Not Enabled", 
      4 => "Allocation",
      5 => "Invalid Handle",
      6 => "No Driver",
      7 => "No Memory",
      8 => "Not Supported",
      9 => "Bad Error Number",
      10 => "Invalid Flag",
      11 => "Invalid Parameter",
      12 => "Handle Busy",
      13 => "Invalid Alias"
    }
    
    module WinTypeAliases
      # Byte (8 bits). Declared as unsigned char.
      BYTE = :uchar
      # 32-bit unsigned integer. The range is 0 through 4,294,967,295 decimal.
      DWORD = :uint32
      # Unsigned long type for pointer precision. Use when casting a pointer to a long type.
      DWORD_PTR = :ulong

      # (L) Handle to an object. WinNT.h: #typedef PVOID HANDLE;
      HANDLE = :ulong

      # Handle for a MIDI input device.
      HMIDIIN = HANDLE

      # Handle for a MIDI output device.
      HMIDIOUT = HANDLE

      # public static enum MMRESULT : uint
      # {
      #   MMSYSERR_NOERROR        = 0,
      #   MMSYSERR_ERROR          = 1,
      #   MMSYSERR_BADDEVICEID    = 2,
      #   MMSYSERR_NOTENABLED     = 3,
      #   MMSYSERR_ALLOCATED      = 4,
      #   MMSYSERR_INVALHANDLE    = 5,
      #   MMSYSERR_NODRIVER       = 6,
      #   MMSYSERR_NOMEM          = 7,
      #   MMSYSERR_NOTSUPPORTED   = 8,
      #   MMSYSERR_BADERRNUM      = 9,
      #   MMSYSERR_INVALFLAG      = 10,
      #   MMSYSERR_INVALPARAM     = 11,
      #   MMSYSERR_HANDLEBUSY     = 12,
      #   MMSYSERR_INVALIDALIAS   = 13,
      #   MMSYSERR_BADDB          = 14,
      #   MMSYSERR_KEYNOTFOUND    = 15,
      #   MMSYSERR_READERROR      = 16,
      #   MMSYSERR_WRITEERROR     = 17,
      #   MMSYSERR_DELETEERROR    = 18,
      #   MMSYSERR_VALNOTFOUND    = 19,
      #   MMSYSERR_NODRIVERCB     = 20,
      #   WAVERR_BADFORMAT        = 32,
      #   WAVERR_STILLPLAYING     = 33,
      #   WAVERR_UNPREPARED       = 34
      # }
      MMRESULT = :uint

      # Unsigned INT_PTR.
      UINT_PTR = :uint

      # 16-bit unsigned integer. The range is 0 through 65535 decimal.
      WORD = :ushort
    end
    
    class MIDIEvent < FFI::Struct
      layout :dwDeltaTime, :ulong,
        :dwStreamID, :ulong,
        :dwEvent, :ulong,
        :dwParms, [:ulong, 8]
    end
    
    class MIDIHdr < FFI::Struct
      include WinTypeAliases
      layout :lpData, :pointer,
        :dwBufferLength, DWORD,
        :dwBytesRecorded, DWORD,
        :dwUser, DWORD_PTR,
        :dwFlags, DWORD,
        :lpNext, :pointer,
        :reserved, DWORD_PTR,
        :dwOffset, DWORD,
        :dwReserved, DWORD_PTR  
        
        def write_data(size, string = '')
          ptr = FFI::MemoryPointer.new(:char, size)
          blank = " " * (size-string.length-1)
          ptr.put_string(0, string + blank)
          self[:lpData] = ptr
          self[:dwBufferLength] = string.length
        end
    end
    
    class MIDIInputInfo < FFI::Struct
      include WinTypeAliases
      layout :wMid, WORD,
       :wPid, WORD,
       :vDriverVersion, :ulong,
       :szPname, [:char, 32],
       :dwSupport, DWORD
    end
    
    class MIDIOutputInfo < FFI::Struct
       include WinTypeAliases
       layout :wMid, WORD,
         :wPid, WORD,
         :vDriverVersion, :ulong,
         :szPname, [:char, 32],
         :wTechnology, WORD,
         :wVoices, WORD,
         :wNotes, WORD,
         :wChannelMask, WORD,
         :dwSupport, DWORD
    end
    
    DeviceInfo = {
    
    :input => MIDIInputInfo,
    :output => MIDIOutputInfo

    }
    
    include WinTypeAliases
    
    # void CALLBACK MidiInProc(HMIDIIN hMidiIn,UINT wMsg,DWORD_PTR dwInstance,DWORD_PTR dwParam1,DWORD_PTR dwParam2)
    callback :input_callback, [:pointer, :uint, DWORD_PTR, DWORD_PTR, DWORD_PTR], :void
    
    # void CALLBACK MidiOutProc(HMIDIOUT hmo, UINT wMsg, DWORD_PTR dwInstance, DWORD_PTR dwParam1, DWORD_PTR dwParam2)
    callback :output_callback, [:pointer, :uint, DWORD_PTR, DWORD_PTR, DWORD_PTR], :void

    #
    # initialize/close devices
    #

    # MMRESULT midiInOpen(LPHMIDIIN lphMidiIn, UINT_PTR uDeviceID, DWORD_PTR dwCallback, DWORD_PTR dwCallbackInstance, DWORD dwFlags)
    # LPHMIDIIN = *HMIDIIN
    attach_function :midiInOpen, [:pointer, UINT_PTR, :input_callback, DWORD_PTR, DWORD], MMRESULT
    
    # MMRESULT midiOutOpen(LPHMIDIOUT lphmo, UINT uDeviceID, DWORD_PTR dwCallback, DWORD_PTR dwCallbackInstance, DWORD dwFlags)
    # LPHMIDIOUT = *HMIDIOUT
    # :output_callback
    attach_function :midiOutOpen, [:pointer, :uint, :output_callback, DWORD_PTR, DWORD], MMRESULT
    
    attach_function :midiInClose, [:ulong], :ulong
    attach_function :midiOutClose, [:ulong], :ulong
    attach_function :midiInReset, [:pointer], :ulong
    
    # MMRESULT midiOutReset(HMIDIOUT hmo)
    attach_function :midiOutReset, [HMIDIOUT], MMRESULT
    
    #
    # for message output
    #
    
    # MMRESULT midiOutShortMsg(HMIDIOUT hmo, DWORD dwMsg)
    attach_function :midiOutShortMsg, [HMIDIOUT, DWORD], MMRESULT
    
    # MMRESULT midiOutLongMsg(HMIDIOUT hmo, LPMIDIHDR lpMidiOutHdr,UINT cbMidiOutHdr)
    # LPMIDIHDR = *MIDIHDR
    attach_function :midiOutLongMsg, [HMIDIOUT, :pointer, :uint], MMRESULT
    
    # MMRESULT midiStreamOpen(LPHMIDISTRM lphStream,LPUINT puDeviceID, DWORD cMidi, DWORD_PTR dwCallback, DWORD_PTR dwInstance, DWORD fdwOpen)
    attach_function :midiStreamOpen, [:pointer, :pointer, DWORD, DWORD_PTR, DWORD_PTR, DWORD], MMRESULT    

    # MMRESULT midiOutPrepareHeader(HMIDIOUT hmo, LPMIDIHDR lpMidiOutHdr, UINT cbMidiOutHdr)
    attach_function :midiOutPrepareHeader, [HMIDIOUT, :pointer, :uint], MMRESULT
    
    #MMRESULT midiOutUnprepareHeader(HMIDIOUT hmo, LPMIDIHDR lpMidiOutHdr, UINT cbMidiOutHdr)
    attach_function :midiOutUnprepareHeader, [HMIDIOUT, :ulong, :uint], MMRESULT
    
    #MMRESULT midiOutGetVolume(HMIDIOUT hmo, LPDWORD lpdwVolume)
    attach_function :midiOutGetVolume, [HMIDIOUT, :pointer], MMRESULT
    
    # MMRESULT midiOutSetVolume(HMIDIOUT hmo, DWORD dwVolume)
    attach_function :midiOutSetVolume, [HMIDIOUT, DWORD], MMRESULT
    
    #
    # input
    #

    # MMRESULT midiInPrepareHeader(HMIDIIN hMidiIn, LPMIDIHDR lpMidiInHdr, UINT cbMidiInHdr)
    attach_function :midiInPrepareHeader, [HMIDIIN, :pointer, :uint], MMRESULT
    
    attach_function :midiInUnprepareHeader, [HMIDIIN, :pointer, :uint], MMRESULT
    attach_function :midiInAddBuffer, [HMIDIIN, :pointer, :uint], MMRESULT
    
    # MMRESULT midiInStart(HMIDIIN hMidiIn)
    attach_function :midiInStart, [HMIDIIN], MMRESULT
    
    # MMRESULT midiInStop(HMIDIIN hMidiIn)
    attach_function :midiInStop, [HMIDIIN], MMRESULT
    
    #
    # enumerate devices
    #
    
    # UINT midiInGetNumDevs(void)
    attach_function :midiInGetNumDevs, [], :uint
    
    # UINT midiOutGetNumDevs(void)
    attach_function :midiOutGetNumDevs, [], :uint
    
    # MMRESULT midiInGetDevCaps(UINT_PTR uDeviceID, LPMIDIINCAPS lpMidiInCaps, UINT cbMidiInCaps);
    attach_function :midiInGetDevCapsA, [UINT_PTR, :pointer, :uint], MMRESULT
    
    attach_function :midiOutGetDevCapsA, [UINT_PTR, :pointer, :uint], MMRESULT
   
    # shortcut for calling winmm midi functions
    def self.cfunc(type, funcname, *args)
      t = type.to_s.gsub(/put/,'') # convert output to out, input to in
      name = funcname.to_s
      name[0] = name[0,1].upcase # capitalize
      t[0] = t[0,1].upcase # capitalize
      self.send("midi#{t}#{name}", *args)
    end
    
    def self.winmm_func(name, *args)
      status = self.send(name, *args)
      raise "#{name.to_s}: #{error(status)}" if error?(status)
    end
    
    def self.error?(num)
      !Map::Errors[num].nil?
    end
      
    def self.error(num)
      Map::Errors[num]
    end
    
  end
end