require 'rbcl/lib/mud_connection'

module RbCl
  class Client
    def initialize(ui)
      @ui = ui
      @ui.client = self
      @ui.prompt = '>'

      @last_line = nil

      @map_trigger_start = '<MAPSTART>'
      @map_trigger_end = '<MAPEND>'
    end

    def handle_command(cmd)
      if cmd.strip.start_with?('#')
        handle_internal_command(cmd)
      elsif @connection
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
      debug('Connection opened')
    end

    def connection_closed
      debug('Connection closed')
    end

    # process mud output coming from @connection
    # stores last chunk of text that did not contain "\n" for prompt detection
    def process(text)
      lines = text.split("\n")
      return if lines.count == 0

      if @last_line
        lines[0] = @last_line + lines[0]
        @last_line = nil
      end

      lines.each_with_index do |line, i|
        if line.index(@map_trigger_start) # if this line starts the map trigger
          @ui.print(line[0..line.index(@map_trigger_start) - 1]) if line.index(@map_trigger_start) > 0
          @map_buffer = line[(line.index(@map_trigger_start) + @map_trigger_start.length)..-1] + "\n"
        elsif @map_buffer && !line.index(@map_trigger_end) # else if already reading into map buffer and not seeing the end tag
          @map_buffer += line + "\n"
        elsif @map_buffer && line.index(@map_trigger_end) # if reading into map buffer and seeing the end tag
          # read the map until the end and display it
          @map_buffer += line[0..line.index(@map_trigger_end) - 1]
          @ui.map_text = @map_buffer
          @map_buffer = nil
          
          l = line[line.index(@map_trigger_end) + @map_trigger_end.length + 1..-1]
          @ui.print(l.to_s + "\n") # print the remainder of the line, if any
        elsif !@map_buffer && i == lines.length - 1 && text[-1] != "\n" # if not reading into map buffer and last received line is not terminated by "\n"
          @last_line = lines[i]
          @ui.print(@last_line)
        else
          @ui.print(line + "\n")
        end
      end
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
        @last_line = ''
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
      when 'char.status'
        @ui.char_status = data
      when 'char.worth'
        @ui.char_worth = data
      when 'room.info'
        @ui.room_info = data
      end
    end

    def handle_internal_command(command)
      components = command.strip[1..-1].split(/\s+/)
      case components[0]
      when 'gmcp'
        @connection.send_gmcp(components[1], components[2..-1].join(' '))
      end
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
      return if %w(say mobsay).include?(data['chan'])
      @ui.print(data['msg'] + "\n", data['chan'])
    end
  end
end
