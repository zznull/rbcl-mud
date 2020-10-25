require 'rbcl/lib/mud_connection'

module RbCl
  class Client
    attr_reader :ui
    attr_accessor :buffer_last_line, :gmcp_block

    def initialize(ui)
      @ui = ui
      @ui.client = self
      @ui.prompt = '>'

      @mud_output_buffer = ''

      @triggers = []
      @trigger_buffer = ''
      @current_trigger = nil

      @last_line = nil

      @gmcp_triggers = {}
    end

    def self.load(mud_file_path, ui)
      client = new(ui)
      eval(File.read(mud_file_path))
    end

    def handle_command(cmd)
      if cmd.strip.start_with?('#') # if this is an internal (client) command
        handle_internal_command(cmd)
        return
      elsif @connection # this is a command for the mud
        @connection.write(cmd + "\n")
      end

      unless @suppress_echo
        @ui.print(cmd + "\n")
      else
        @ui.print("\n")
      end
    end

    def connect(host, port = 23)
      @ui.print("Connecting to #{host}:#{port}\n")
      @connection = MudConnection.new(host, port, self)
    end

    def connection_opened
      @ui.focus_prompt
    end

    def connection_closed
      debug('Connection closed')
    end

    # process mud output coming from @connection
    # stores last chunk of text that did not contain "\n" for prompt detection
    def process(text)
      @mud_output_buffer += text
      
      while find_trigger
        i_start = @mud_output_buffer.index(@current_trigger[:start_str])
        if i_start
          @ui.print(@mud_output_buffer[0..i_start - 1])
          @mud_output_buffer = @mud_output_buffer[i_start + @current_trigger[:start_str].length .. -1]
        end

        i_end = find_trigger_end
        if i_end
          @trigger_buffer += @mud_output_buffer[0 .. i_end - 1]
          @current_trigger[:block].call(@trigger_buffer)
          @trigger_buffer = ''
          @mud_output_buffer = @mud_output_buffer[i_end + @current_trigger[:end_str].length .. -1]
          @current_trigger = nil
        else
          return # reading into trigger, end_str not found, we wait until it arrives
        end
      end

      if @mud_output_buffer.rindex("\n") && @buffer_last_line
        @ui.print(@mud_output_buffer[0 .. @mud_output_buffer.rindex("\n")])
        @last_line = @mud_output_buffer[@mud_output_buffer.rindex("\n") .. -1]
      else
        @ui.print(@mud_output_buffer)
      end

      @mud_output_buffer = ''
    end

    # finds first trigger that starts in the buffer
    def find_trigger
      return if @current_trigger # we don't support triggers within triggers

      i = @triggers.find_index do |trigger|
        @mud_output_buffer.index(trigger[:start_str])
      end

      @current_trigger = @triggers[i] if i
    end 

    # finds position of the current trigger's end_str
    def find_trigger_end
      return unless @current_trigger

      @mud_output_buffer.index(@current_trigger[:end_str])
    end

    # adds a multiline trigger
    def add_trigger(start_str, end_str, &block)
      @triggers << {
        start_str: start_str,
        end_str: end_str,
        block: block
      }
    end

    def add_gmcp_trigger(package, &block)
      @gmcp_triggers[package.downcase] = block
    end

    # prints text to the debug console
    def debug(text)
      text = text + "\n" unless text.end_with?("\n")
      @ui.debug(text)
    end

    # GO AHEAD and END OF RECORD prompt detection
    def go_ahead
      if @last_line && @last_line.strip != ''
        @ui.prompt = @last_line
        @last_line = nil
      end
    end

    # masks/unmasks prompt input
    def suppress_echo(val)
      @suppress_echo = val
      @ui.hide_prompt_text(val)
    end

    # returns main output window dimensions in characters
    def window_size
      @ui.window_size
    end

    def window_resized(size)
      debug("Sending window size #{size.join('x')}")
      @connection.send_window_size(size) if @connection
    end

    def process_atcp(data)
      debug("ATCP #{data}")
    end

    def process_gmcp(package, json)
      debug("GMCP #{package}")
      debug(json)

      data = parse_json(json)

      case package.downcase
      when 'comm.channel'
        process_gmcp_channel(data)
      when 'char.vitals'
        @ui.char_vitals = data
      when 'char.maxstats'
        @ui.char_maxstats = data
      when 'char.base'
        @ui.char_base = data
      end

      @gmcp_triggers[package.downcase].call(data) if @gmcp_triggers[package.downcase]
    end

    def handle_internal_command(command)
      components = command.strip[1..-1].split(/\s+/)
      case components[0]
      when 'gmcp'
        @connection.send_gmcp(components[1], components[2..-1].join(' '))
      when 'connect'
        if components.length >= 2 && components.length <= 3
          connect(components[1], components[2] ? components[2].to_i : 23)
        else
          @ui.print("Syntax: \#connect host [port]\n")
        end
      end
    end

    def map=(text)
      @ui.map_text = text
    end

    def show_info=(val)
      @ui.show_info = val
    end

    protected

    def parse_json(json)
      escaped_json = json.gsub("\e", '__ESCAPED_E_')
      parsed = JSON.parse(escaped_json)
      return unescape_json(parsed)
    end

    def unescape_json(value)
      if value.is_a? String
        value.gsub!('__ESCAPED_E_', "\e")
      elsif value.is_a? Array
        value.map! { |el| unescape_json(el) }
      elsif value.is_a? Hash
        value.each_pair do |key, el|
          el = unescape_json(el)
        end
      end
    end

    def process_gmcp_channel(data)
      return if %w(say).include?(data['chan'])
      @ui.print(data['msg'] + "\n", data['chan'])
    end
  end
end
