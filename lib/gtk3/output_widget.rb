require 'rbcl/lib/gtk3/output_buffer'
require 'rbcl/lib/ansi_printer'

module RbCl
  module UI
    class OutputWidget < Gtk::TextView
      def initialize
        super

        set_buffer(OutputBuffer.new)

        set_name('output-widget')
        set_editable(false)
        set_monospace(true)
        set_cursor_visible(false)
        set_wrap_mode(Gtk::WrapMode::WORD_CHAR)
      end

      def print(text)
        buffer.print(text)
      end

      def clear
        buffer.clear
      end

      def char_size
        # font set from css, make sure this font description matches that value
        # TODO: set font (and other style attributes) from a dialog, use that here
        pango_layout = create_pango_layout
        font_description = Pango::FontDescription.new
        font_description.family = 'Inconsolata'
        font_description.size = 16 * Pango::SCALE
        pango_layout.font_description = font_description
        pango_layout.text = 'M'

        pango_layout.pixel_size
      end

      def keep_scrollback=(value)
        buffer.keep_scrollback(value)
      end
    end
  end
end
