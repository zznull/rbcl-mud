class AnsiPrinter
  CSI = "\e["
  CSI_END_RANGE = '@'..'~'

  def initialize(printer)
    @printer = printer
    @buffer = ''
  end

  # calls @printer.print for text and appropriate methods for ANSI escape sequences
  def print(input_str)
    str = @buffer + input_str
    @buffer = ''

    catch :sequence_incomplete do
      loop do
        i_seq = str.index "\e"
        if !i_seq.nil?
          @printer.print_direct(str.slice!(0, i_seq))
          seq = get_sequence(str)
          execute_sequence(seq)
        else
          @printer.print_direct(str)
          return
        end
      end
    end
    @buffer = str
  end

  private

  class UnsupportedSequence < Exception
  end

  # removes and returns an ANSI sequence from beginning of input_str
  # currently only looks for CSI sequences
  def get_sequence(input_str)
    throw :sequence_incomplete if input_str[1].nil?

    if input_str[1] == '[' # we have a CSI
      return get_csi(input_str)
    else
      # raise UnsupportedSequence, input_str
      input_str.slice!(0, 2)
    end
  end

  def get_csi(input_str)
    csi = "\e["
    input_str[2..-1].each_char do |char| # loop until csi terminating char found
      csi += char

      if CSI_END_RANGE.include?(char)
        input_str.slice!(0, csi.length)
        return csi
      end
    end

    # didn't return from block above => end of string reached without complete CSI
    throw :sequence_incomplete
  end

  # calls the appropriate method for an ANSI escape sequence
  def execute_sequence(sequence)
    if sequence[-1] == 'm' # SGR
      sgr_codes = sequence[2..-2].split(';')
      sgr_codes = [0] if sgr_codes.count == 0
      @printer.ansi_sgr(sgr_codes)
    end
  end
end
