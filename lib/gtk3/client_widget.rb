require 'pry'
require 'glib2'
require 'lib/gtk3/communication_widget'
require 'lib/gtk3/prompt_widget'
require 'lib/gtk3/info_widget'
require 'lib/gtk3/css_support'
require 'lib/gtk3/output_widget'

module RbCl
  module UI
    class ClientWidget < Gtk::Box
      include CssSupport

      def initialize()
        super :horizontal

        @communication_widget = CommunicationWidget.new
        @communication_widget.show

        set_name('client-widget')
        load_css

        pack_start(@communication_widget, fill: true, expand: true)

        @info_widget = InfoWidget.new
        @info_widget.set_width_request(350)
        @info_widget.show
        pack_end(@info_widget, fill: true, shrink: false)
      end

      def info
        @info_widget
      end

      def client=(c)
        @client = c
        @communication_widget.client = @client
      end

      def prompt=(val)
        @communication_widget.prompt = val

      end

      def debug(text)
        @communication_widget.debug(text)
      end

      def print(text, channel = 'main')
        @communication_widget.print(text, channel)
      end

      def focus_prompt
        @communication_widget.focus_prompt
      end

      def window_size
        @communication_widget.window_size
      end

      def hide_prompt_text(val)
        @communication_widget.hide_prompt_text(val)
      end

      def char_vitals=(data)
        @info_widget.char_vitals = data
      end

      def char_maxstats=(data)
        @info_widget.char_maxstats = data
      end

      def char_base=(data)
        @info_widget.char_base = data
      end

      def map_text=(text)
        @info_widget.map_text = text
      end

      def room_info=(data)
        @info_widget.room_info = data
      end

      def show_info=(val)
        if val
          @info_widget.show
        else
          @info_widget.hide
        end
      end
    end
  end
end