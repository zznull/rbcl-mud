module RbCl
  module UI
    class OutputBuffer < Gtk::TextBuffer
      def initialize
        super

        @ansi_printer = AnsiPrinter.new(self)
        @max_line_count = 1000

        create_tags
        create_tags_256
      end

      def print(str)
        @ansi_printer.print(str)
      end

      def clear
        delete(start_iter, end_iter)
      end

      def print_direct(str)
        str = sanitize(str)
        insert(end_iter, str)

        limit_line_count

        i = end_iter
        i.backward_chars(str.length)

        current_tags.each do |tag|
          apply_tag(tag, i, end_iter)
        end

        true
      end

      # loops through an ansi escape sequence and sets colors based on its contents
      def ansi_sgr(sgr_codes)
        i = 0
        while i < sgr_codes.length
          sgr_code = sgr_codes[i]

          case sgr_code.to_i
          when 0 then @current_sgr_tags = []
          when 1 then add_sgr_tag('bold')
          when 4 then add_sgr_tag('underline')
          when 30..37 then set_sgr_fg(sgr_code)
          when 40..47 then set_sgr_bg(sgr_code)
          when 5 then
          when 6 then
          when 38 then set_sgr_fg_256(sgr_codes[i + 2]); i += 2
          when 48 then set_sgr_bg_256(sgr_codes[i + 2]); i += 2
          end

          i += 1
        end
      end

      def keep_scrollback(value)
        @keep_scrollback = value
      end

      private

      # adds and ansi color tag to the current sequence
      def add_sgr_tag(name)
        return if @current_sgr_tags.find { |t| t.name == name.to_s }
        tag = tag_table.lookup(name)
        @current_sgr_tags << tag if tag
      end

      # adds an xterm color tag to the current sequence
      def add_sgr_tag_256(name)
        return if @current_sgr_tags.find { |t| t.name == name.to_s }
        tag = tag_table.lookup(name)
        @current_sgr_tags << tag if tag
      end

      def remove_sgr_tag(name)
        @current_sgr_tags.delete_if { |tag| tag.name == name.to_s }
      end

      # sets currently printed text fg from ansi colors
      def set_sgr_fg(sgr_code)
        @current_sgr_tags.delete_if { |tag| tag.name.start_with?('foreground') }
        add_sgr_tag("foreground:#{sgr_code.to_i}")
      end

      # sets currently printed text bg from ansi colors
      def set_sgr_bg sgr_code
        @current_sgr_tags.delete_if { |tag| tag.name.start_with?('background') }
        add_sgr_tag("background:#{sgr_code.to_i}")
      end

      # sets currently printed text fg from xterm colors
      def set_sgr_fg_256(sgr_code)
        @current_sgr_tags.delete_if { |tag| tag.name.start_with?('foreground') }
        add_sgr_tag("foreground_256:#{sgr_code}")
      end

      # sets currently printed text bg from xterm colors
      def set_sgr_bg_256(sgr_code)
        @current_sgr_tags.delete_if { |tag| tag.name.start_with?('background') }
        add_sgr_tag("background_256:#{sgr_code}")
      end
      def current_tags

        @current_sgr_tags
      end

      # turns #deadbeef into a Gtk::RGBA
      def create_rgba(spec)
        rgba = Gdk::RGBA.new(0, 0, 0, 0)
        rgba.parse(spec)
        rgba
      end

      # creates gtk3 text tags with the standard 16 colors
      def create_tags colors = nil
        @current_sgr_tags = []

        colors = [
          create_rgba('#000000'),
          create_rgba('#c23621'),
          create_rgba('#25bc24'),
          create_rgba('#adad27'),
          create_rgba('#492ee1'),
          create_rgba('#d338d3'),
          create_rgba('#33bbc8'),
          create_rgba('#cbcccd'),

          create_rgba('#818383'),
          create_rgba('#fc391f'),
          create_rgba('#31e722'),
          create_rgba('#eaec23'),
          create_rgba('#5833ff'),
          create_rgba('#f935f8'),
          create_rgba('#14f0f0'),
          create_rgba('#e9ebeb')
        ]

        30.upto(37) { |n| create_tag("foreground:#{n}", 'foreground_rgba' => colors[n - 30]) }
        40.upto(47) { |n| create_tag("background:#{n}", 'background_rgba' => colors[n - 40]) }

        create_tag('bold', 'weight' => Pango::Weight::BOLD)
        create_tag('underline', 'underline' => Pango::Underline::SINGLE)
      end

      # creates gtk3 fg and bg colors for the 256 xterm colors
      def create_tags_256
        colors = [
          create_rgba('#000000'),
          create_rgba('#800000'),
          create_rgba('#008000'),
          create_rgba('#808000'),
          create_rgba('#000080'),
          create_rgba('#800080'),
          create_rgba('#008080'),
          create_rgba('#c0c0c0'),
          create_rgba('#808080'),
          create_rgba('#ff0000'),
          create_rgba('#00ff00'),
          create_rgba('#ffff00'),
          create_rgba('#0000ff'),
          create_rgba('#ff00ff'),
          create_rgba('#00ffff'),
          create_rgba('#ffffff'),
          create_rgba('#000000'),
          create_rgba('#00005f'),
          create_rgba('#000087'),
          create_rgba('#0000af'),
          create_rgba('#0000d7'),
          create_rgba('#0000ff'),
          create_rgba('#005f00'),
          create_rgba('#005f5f'),
          create_rgba('#005f87'),
          create_rgba('#005faf'),
          create_rgba('#005fd7'),
          create_rgba('#005fff'),
          create_rgba('#008700'),
          create_rgba('#00875f'),
          create_rgba('#008787'),
          create_rgba('#0087af'),
          create_rgba('#0087d7'),
          create_rgba('#0087ff'),
          create_rgba('#00af00'),
          create_rgba('#00af5f'),
          create_rgba('#00af87'),
          create_rgba('#00afaf'),
          create_rgba('#00afd7'),
          create_rgba('#00afff'),
          create_rgba('#00d700'),
          create_rgba('#00d75f'),
          create_rgba('#00d787'),
          create_rgba('#00d7af'),
          create_rgba('#00d7d7'),
          create_rgba('#00d7ff'),
          create_rgba('#00ff00'),
          create_rgba('#00ff5f'),
          create_rgba('#00ff87'),
          create_rgba('#00ffaf'),
          create_rgba('#00ffd7'),
          create_rgba('#00ffff'),
          create_rgba('#5f0000'),
          create_rgba('#5f005f'),
          create_rgba('#5f0087'),
          create_rgba('#5f00af'),
          create_rgba('#5f00d7'),
          create_rgba('#5f00ff'),
          create_rgba('#5f5f00'),
          create_rgba('#5f5f5f'),
          create_rgba('#5f5f87'),
          create_rgba('#5f5faf'),
          create_rgba('#5f5fd7'),
          create_rgba('#5f5fff'),
          create_rgba('#5f8700'),
          create_rgba('#5f875f'),
          create_rgba('#5f8787'),
          create_rgba('#5f87af'),
          create_rgba('#5f87d7'),
          create_rgba('#5f87ff'),
          create_rgba('#5faf00'),
          create_rgba('#5faf5f'),
          create_rgba('#5faf87'),
          create_rgba('#5fafaf'),
          create_rgba('#5fafd7'),
          create_rgba('#5fafff'),
          create_rgba('#5fd700'),
          create_rgba('#5fd75f'),
          create_rgba('#5fd787'),
          create_rgba('#5fd7af'),
          create_rgba('#5fd7d7'),
          create_rgba('#5fd7ff'),
          create_rgba('#5fff00'),
          create_rgba('#5fff5f'),
          create_rgba('#5fff87'),
          create_rgba('#5fffaf'),
          create_rgba('#5fffd7'),
          create_rgba('#5fffff'),
          create_rgba('#870000'),
          create_rgba('#87005f'),
          create_rgba('#870087'),
          create_rgba('#8700af'),
          create_rgba('#8700d7'),
          create_rgba('#8700ff'),
          create_rgba('#875f00'),
          create_rgba('#875f5f'),
          create_rgba('#875f87'),
          create_rgba('#875faf'),
          create_rgba('#875fd7'),
          create_rgba('#875fff'), 
          create_rgba('#878700'),
          create_rgba('#87875f'),
          create_rgba('#878787'),
          create_rgba('#8787af'),
          create_rgba('#8787d7'),
          create_rgba('#8787ff'),
          create_rgba('#87af00'),
          create_rgba('#87af5f'),
          create_rgba('#87af87'),
          create_rgba('#87afaf'),
          create_rgba('#87afd7'),
          create_rgba('#87afff'),
          create_rgba('#87d700'),
          create_rgba('#87d75f'),
          create_rgba('#87d787'),
          create_rgba('#87d7af'),
          create_rgba('#87d7d7'),
          create_rgba('#87d7ff'),
          create_rgba('#87ff00'),
          create_rgba('#87ff5f'),
          create_rgba('#87ff87'),
          create_rgba('#87ffaf'),
          create_rgba('#87ffd7'),
          create_rgba('#87ffff'),
          create_rgba('#af0000'),
          create_rgba('#af005f'),
          create_rgba('#af0087'),
          create_rgba('#af00af'),
          create_rgba('#af00d7'),
          create_rgba('#af00ff'),
          create_rgba('#af5f00'),
          create_rgba('#af5f5f'),
          create_rgba('#af5f87'),
          create_rgba('#af5faf'),
          create_rgba('#af5fd7'),
          create_rgba('#af5fff'),
          create_rgba('#af8700'),
          create_rgba('#af875f'),
          create_rgba('#af8787'),
          create_rgba('#af87af'),
          create_rgba('#af87d7'),
          create_rgba('#af87ff'),
          create_rgba('#afaf00'),
          create_rgba('#afaf5f'),
          create_rgba('#afaf87'),
          create_rgba('#afafaf'),
          create_rgba('#afafd7'),
          create_rgba('#afafff'),
          create_rgba('#afd700'),
          create_rgba('#afd75f'),
          create_rgba('#afd787'),
          create_rgba('#afd7af'),
          create_rgba('#afd7d7'),
          create_rgba('#afd7ff'),
          create_rgba('#afff00'),
          create_rgba('#afff5f'),
          create_rgba('#afff87'),
          create_rgba('#afffaf'),
          create_rgba('#afffd7'),
          create_rgba('#afffff'),
          create_rgba('#d70000'),
          create_rgba('#d7005f'),
          create_rgba('#d70087'),
          create_rgba('#d700af'),
          create_rgba('#d700d7'),
          create_rgba('#d700ff'),
          create_rgba('#d75f00'),
          create_rgba('#d75f5f'),
          create_rgba('#d75f87'),
          create_rgba('#d75faf'),
          create_rgba('#d75fd7'),
          create_rgba('#d75fff'),
          create_rgba('#d78700'),
          create_rgba('#d7875f'),
          create_rgba('#d78787'),
          create_rgba('#d787af'),
          create_rgba('#d787d7'),
          create_rgba('#d787ff'),
          create_rgba('#d7af00'),
          create_rgba('#d7af5f'),
          create_rgba('#d7af87'),
          create_rgba('#d7afaf'),
          create_rgba('#d7afd7'),
          create_rgba('#d7afff'),
          create_rgba('#d7d700'),
          create_rgba('#d7d75f'),
          create_rgba('#d7d787'),
          create_rgba('#d7d7af'),
          create_rgba('#d7d7d7'),
          create_rgba('#d7d7ff'),
          create_rgba('#d7ff00'),
          create_rgba('#d7ff5f'),
          create_rgba('#d7ff87'),
          create_rgba('#d7ffaf'),
          create_rgba('#d7ffd7'),
          create_rgba('#d7ffff'),
          create_rgba('#ff0000'),
          create_rgba('#ff005f'),
          create_rgba('#ff0087'),
          create_rgba('#ff00af'),
          create_rgba('#ff00d7'),
          create_rgba('#ff00ff'),
          create_rgba('#ff5f00'),
          create_rgba('#ff5f5f'),
          create_rgba('#ff5f87'),
          create_rgba('#ff5faf'),
          create_rgba('#ff5fd7'),
          create_rgba('#ff5fff'),
          create_rgba('#ff8700'),
          create_rgba('#ff875f'),
          create_rgba('#ff8787'),
          create_rgba('#ff87af'),
          create_rgba('#ff87d7'),
          create_rgba('#ff87ff'),
          create_rgba('#ffaf00'),
          create_rgba('#ffaf5f'),
          create_rgba('#ffaf87'),
          create_rgba('#ffafaf'),
          create_rgba('#ffafd7'),
          create_rgba('#ffafff'),
          create_rgba('#ffd700'),
          create_rgba('#ffd75f'),
          create_rgba('#ffd787'),
          create_rgba('#ffd7af'),
          create_rgba('#ffd7d7'),
          create_rgba('#ffd7ff'),
          create_rgba('#ffff00'),
          create_rgba('#ffff5f'),
          create_rgba('#ffff87'),
          create_rgba('#ffffaf'),
          create_rgba('#ffffd7'),
          create_rgba('#ffffff'),
          create_rgba('#080808'),
          create_rgba('#121212'),
          create_rgba('#1c1c1c'),
          create_rgba('#262626'),
          create_rgba('#303030'),
          create_rgba('#3a3a3a'),
          create_rgba('#444444'),
          create_rgba('#4e4e4e'),
          create_rgba('#585858'),
          create_rgba('#626262'),
          create_rgba('#6c6c6c'),
          create_rgba('#767676'),
          create_rgba('#808080'),
          create_rgba('#8a8a8a'),
          create_rgba('#949494'),
          create_rgba('#9e9e9e'),
          create_rgba('#a8a8a8'),
          create_rgba('#b2b2b2'),
          create_rgba('#bcbcbc'),
          create_rgba('#c6c6c6'),
          create_rgba('#d0d0d0'),
          create_rgba('#dadada'),
          create_rgba('#e4e4e4'),
          create_rgba('#eeeeee')
        ]

        colors.each_with_index { |color, i| create_tag("foreground_256:#{i.to_s.rjust(3, '0')}", 'foreground_rgba' => color) }
        colors.each_with_index { |color, i| create_tag("background_256:#{i.to_s.rjust(3, '0')}", 'background_rgba' => color) }
      end

      def limit_line_count
        if !@keep_scrollback && line_count > @max_line_count
          extra_lines = line_count - @max_line_count
          i = start_iter
          i.forward_lines(extra_lines)
          delete(start_iter, i)
        end
      end

      def sanitize(str)
        str.encode(Encoding::ASCII_8BIT, invalid: :replace, undef: :replace, replace: '')
      end
    end
  end
end
