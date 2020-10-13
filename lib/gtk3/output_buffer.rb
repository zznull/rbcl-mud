module RbCl
  module UI
    class OutputBuffer < Gtk::TextBuffer
      def initialize
        super

        @ansi_printer = AnsiPrinter.new(self)
        @max_line_count = 1000

        create_tags
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

      def ansi_sgr(sgr_codes)
        sgr_codes.each do |sgr_code|
          case sgr_code.to_i
          when 0 then @current_sgr_tags = []
          when 1 then add_sgr_tag('bold')
          when 4 then add_sgr_tag('underline')
          when 30..37 then set_sgr_fg(sgr_code)
          when 40..47 then set_sgr_bg(sgr_code)
          end
        end
      end

      def keep_scrollback(value)
        @keep_scrollback = value
      end

      private

      def add_sgr_tag(name)
        return if @current_sgr_tags.find { |t| t.name == name.to_s }
        tag = tag_table.lookup name
        @current_sgr_tags << tag
      end

      def remove_sgr_tag(name)
        @current_sgr_tags.delete_if { |tag| tag.name == name.to_s }
      end

      def set_sgr_fg(sgr_code)
        @current_sgr_tags.delete_if { |tag| tag.name.start_with? 'foreground:' }
        add_sgr_tag("foreground:#{sgr_code}")
      end

      def set_sgr_bg sgr_code
        @current_sgr_tags.delete_if { |tag| tag.name.start_with? 'background:' }
        add_sgr_tag("background:#{sgr_code}")
      end

      def current_tags
        @current_sgr_tags
      end

      def create_rgba(spec)
        rgba = Gdk::RGBA.new(0, 0, 0, 0)
        rgba.parse(spec)
        rgba
      end

      def create_tags colors = nil
        @current_sgr_tags = []

        colors ||= [
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
