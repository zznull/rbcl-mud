require 'glib2'

require 'lib/gtk3/multiple_output_widget'
require 'lib/gtk3/prompt_widget'
require 'lib/gtk3/css_support'

module RbCl
  module UI
    class CommunicationWidget < Gtk::Box
      include CssSupport

      attr_accessor :client

      def initialize()
        super(:vertical, 0)

        set_name('communication-widget')
        load_css

        @multiple_output_widget = MultipleOutputWidget.new
        @multiple_output_widget.show
        pack_start(@multiple_output_widget, expand: true, fill: true)

        @multiple_output_widget.on_resized do |size|
          client.window_resized(size)
        end

        @multiple_output_widget.on_tab_switch { focus_prompt }

        @prompt_widget = PromptWidget.new
        add_css_provider(@prompt_widget.style_context)

        @prompt_widget.on_enter do |command|
          @client.handle_command(command)
        end

        pack_end(@prompt_widget, expand: false, fill: false)
        @prompt_widget.show
        focus_prompt
      end

      def print(text, window = 'main')
        @multiple_output_widget.print(text, window)
      end

      def debug(text)
        @multiple_output_widget.print(text, 'debug')
      end

      def focus_prompt
        GLib::Timeout.add(100) { @prompt_widget.grab_focus; false }
      end

      def hide_prompt_text(val)
        @prompt_widget.set_visibility(!val)
      end

      def prompt=(text)
        @prompt_widget.prompt = text
      end

      def window_size
        @multiple_output_widget.window_size
      end
    end
  end
end
