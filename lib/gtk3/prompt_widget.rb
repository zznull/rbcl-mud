require 'rbcl/lib/gtk3/output_buffer'
require 'rbcl/lib/ansi_printer'
require 'rbcl/lib/gtk3/css_support'


module RbCl
  module UI
    class PromptWidget < Gtk::Box
      include CssSupport

      def initialize
        super(Gtk::Orientation::HORIZONTAL, 0)

        load_css

        @output_widget = OutputWidget.new
        @output_widget.set_name('output-widget')
        @output_widget.style_context.add_provider(css_provider, 800)
        @output_widget.set_editable(false)
        @output_widget.set_cursor_visible(false)
        @output_widget.set_wrap_mode(Gtk::WrapMode::NONE)
        @output_widget.set_margin_top(7)
        @output_widget.show
        pack_start(@output_widget, expand: false, fill: false)

        @input = Gtk::Entry.new
        @input.set_name('input')
        @input.style_context.add_provider(css_provider, 800)

        font_description = Pango::FontDescription.new
        font_description.family = 'Inconsolata'
        font_description.size = 16 * Pango::SCALE
        @input.override_font(font_description)

        @input.show

        @input.signal_connect('activate') { command_entered }
        @input.signal_connect('key-press-event') { |input, event| key_pressed(event) }

        pack_end(@input, expand: true, fill: true)

        set_name('prompt-widget')

        @history = []
        @history_max_commands = 1000
        @history_selected_command = 0 # -1 -> last command, 0 -> not in history
        @current_command = ''
      end

      def on_enter(&block)
        @enter_callback = block
      end

      def prompt
        @output_widget.buffer.text
      end

      def prompt= val
        @output_widget.buffer.delete(@output_widget.buffer.start_iter, @output_widget.buffer.end_iter)
        @output_widget.print(val)

        val
      end

      def grab_focus
        @input.grab_focus
      end

      def set_visibility(val)
        @input.set_visibility(val)
      end

      protected

      def text
        @input.text
      end

      def command_entered
        @enter_callback.call(text)

        @history_selected_command = 0
        @history.push(text) unless text.strip == '' || @history[-1] == text
        @history.slice!(0, @history.count - @history_max_commands) if @history.count > @history_max_commands

        @input.buffer.text = ''

        true # return true to signal handler
      end

      def key_pressed(event)
        if event.keyval == Gdk::Keyval::KEY_Up
          history_back
          grab_focus
          return true # prevent from propagating further
        elsif event.keyval == Gdk::Keyval::KEY_Down
          history_forward
          grab_focus
          return true # prevent from propagating further
        elsif event.keyval == Gdk::Keyval::KEY_Tab
          return true
        end

        false
      end

      def history_back
        if @history_selected_command == 0
          @current_command = text
        end

        if @history_selected_command > -@history.count
          @history_selected_command -= 1
          @input.buffer.text = @history[@history_selected_command]
          @input.select_region(0, text.length)
        end
      end

      def history_forward
        if @history_selected_command < 0
          @history_selected_command += 1

          if @history_selected_command == 0
            @input.buffer.text = @current_command
          else
            @input.buffer.text = @history[@history_selected_command]
          end

          @input.select_region(0, text.length)
        end
      end
    end
  end
end
