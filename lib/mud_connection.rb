require 'zlib'
require 'rbcl/lib/connection'
require 'json'

module RbCl
  class MudConnection < Connection
    EOR = 239.chr
    SE = 240.chr
    GA = 249.chr
    SB = 250.chr
    WILL = 251.chr
    WONT = 252.chr
    DO = 253.chr
    DONT = 254.chr
	  IAC = 255.chr

    IS = 0.chr
    ECHO = 1.chr
    SEND = 1.chr
    TERMINAL_TYPE = 24.chr
    END_OF_RECORD = 25.chr
    NAWS = 31.chr
    MCCP = 86.chr
    ATCP = 200.chr
    GMCP = 201.chr
    TELOPT_EOR = 25.chr

    TerminalTypes = ["RBCL", "ANSI", "DUMB"]

    def initialize(host, port, client)
      super(host, port, client)
      @buffer = ''
      @options = {}

      @next_terminal_type = 0
    end

    def send_window_size(size = nil)
      if @options[NAWS]
        size = @client.window_size if size.nil?
        send_seq(IAC + SB + NAWS + size.pack('n*') + IAC + SE)
      end
    end

    def send_gmcp(package, message)
      log(">IAC SB GMCP #{package} #{message}")
      send_seq(IAC + SB + GMCP + package + ' ' + message)
    end

    private

    # removes telnet commands from data and passes what remains to client
    def process(data)
      if @inflater
        @buffer = @buffer + @inflater.inflate(data)
      else
        @buffer = @buffer + data
      end

      # print @buffer

      loop do
        i_iac = @buffer.index(IAC)
        if i_iac.nil?
          @client.process(preprocess(@buffer))
          @buffer = ''
          break
        else
          @client.process(preprocess(@buffer.slice!(0, i_iac)))
          break unless process_command
        end
      end

    rescue Zlib::Error
      @client.debug 'Decompression error occured'
      disconnect
    end

    def preprocess(text)
      text.gsub("\r", '')
    end

    # called when @buffer[0] == IAC
    # if command is complete, processes it and returns true
    # if command is incomplete, leaves it in front of @buffer and returns false
    def process_command
      return false if @buffer[1].nil?

      case @buffer[1]
      when IAC # IAC IAC
        @client.process(IAC)
        @buffer.slice!(0, 2)
        return true
      when WILL
        return false if @buffer[2].nil?
        iac_will
      when WONT
        return false if @buffer[2].nil?
        iac_wont
      when DO
        return false if @buffer[2].nil?
	      iac_do
      when DONT
        return false if @buffer[2].nil?
        iac_dont
      when SB
        iac_sb
      when GA, EOR
        @client.go_ahead
        @buffer.slice!(0, 2)
        true
      else # some other IAC sequence
        log("IAC #{@buffer[1]} (ignoring)")
        @buffer.slice!(0, 2) # remove from buffer and ignore
        true
	    end
    end

    def iac_will
      option = @buffer[2]
      log("IAC WILL #{option.ord}")

      case option
      when ECHO
        send_seq(IAC + DO + ECHO)
        @client.suppress_echo(true)
      when END_OF_RECORD
        send_seq(IAC + DO + END_OF_RECORD)
      when MCCP
        send_seq(IAC + DO + MCCP)
      when ATCP
        send_seq(IAC + DO + ATCP)
      when GMCP
        send_seq(IAC + DO + GMCP)
        send_gmcp_capabilities
      when TELOPT_EOR
        send_seq(IAC + DO + TELOPT_EOR)
      else
        send_seq(IAC + DONT + option)
        @options[option] = false
      end

      @buffer.slice!(0, 3)
      true
    end

    def iac_wont
      option = @buffer[2]
      log("IAC WONT #{option.ord}")

      case option
      when ECHO
        send_seq(IAC + DONT + ECHO)
        @client.suppress_echo(false)
      end

      @buffer.slice!(0, 3)
      true
    end

    def iac_do
      option = @buffer[2]
      log("IAC DO #{option.ord}")
      case option
      when TERMINAL_TYPE
        send_seq(IAC + WILL + TERMINAL_TYPE)
      when NAWS
        @options[NAWS] = true
        send_window_size
      else
        send_seq(IAC + WONT + option)
        @options[option] = false
      end
      @buffer.slice!(0, 3)
      true
    end

    def iac_dont
      option = @buffer[2]
      log("IAC DONT #{option.ord}")
      @buffer.slice!(0, 3)
      true
    end

    def iac_sb
      i_end = @buffer.index(IAC + SE)
      return false if i_end.nil?

      option = @buffer[2]
      parameters = @buffer[3..i_end-1]
      # log "IAC SB #{option.ord} #{parameters.unpack('C*').join(' ')} IAC SE"

      case option
      when TERMINAL_TYPE
        if parameters[0] == SEND # IAC SB TERMINAL_TYPE SEND
          send_seq(IAC + SB + TERMINAL_TYPE + IS + (TerminalTypes[@next_terminal_type] || 'DUMB') + IAC + SE)
          @next_terminal_type += 1
        end
      when MCCP
        log('Enabling MCCP')
        @options[MCCP] = true
        @inflater = Zlib::Inflate.new

        # everything in @buffer following ... IAC SE is compressed
        # feed that into @inflater
        @buffer.slice!(0, i_end + 2)
        @buffer = @inflater.inflate(@buffer)

        return true
      when ATCP
        data = @buffer[3..i_end - 1]
        @client.process_atcp(data)
      when GMCP
        i_space = @buffer.index(' ')
        package = @buffer[3..i_space - 1]
        data = @buffer[i_space + 1..i_end - 1]
        @client.process_gmcp(package, data)
      end

      @buffer.slice!(0, i_end + 2)
      true
    end

    def send_seq(seq)
      words = {
        IAC => 'IAC',
        WILL => 'WILL',
        WONT => 'WONT',
        DO => 'DO',
        DONT => 'DONT',
        SB => 'SB',
        SE => 'SE'
      }

      seq.force_encoding(Encoding::ASCII_8BIT)

      str = '>'
      seq.each_char do |char|

        if words[char]
          str += words[char] + ' '
        else
          str += char.unpack('C*')[0].to_s + ' '
        end
      end

      write(seq)
      log(str)
    end

    def send_gmcp_capabilities
      send_gmcp('Core.Supports.Set', JSON.dump(['Debug 1', 'Char 1', 'Comm 1', 'Room 1']))
    end

    def log(str)
     @client.debug("Telnet: " + str + "\n")
    end
  end
end
