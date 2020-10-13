require 'rbcl/lib/gtk3/client_widget'
require 'rbcl/lib/client'
require 'rbcl/lib/gtk3/css_support'

module RbCl
  module UI
    class MainWindow < Gtk::Window
      include CssSupport

      attr_reader :client_widget

      def initialize application
        super(Gtk::WindowType::TOPLEVEL)

        @application = application

        set_name('main-window')

        load_css
        set_default_size(1280, 800)

        @client_widget = ClientWidget.new

        add(@client_widget)
        @client_widget.show

        signal_connect('destroy') { quit }

        show
      end

      def quit
        @application.quit
      end
    end
  end
end
