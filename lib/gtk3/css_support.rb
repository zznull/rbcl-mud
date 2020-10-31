module RbCl
  module UI
    module CssSupport
      @@css_provider = nil
      
      def self.included(mod)
        unless @@css_provider
          @@css_provider = Gtk::CssProvider.new
          @@css_provider.load(path: 'lib/gtk3/style.css')
        end
      end

      def load_css
        style_context.add_provider(@@css_provider, 800)
      end

      def add_css_provider(style_context)
        style_context.add_provider(css_provider, 800)
      end

      def css_provider
        @@css_provider
      end
    end
  end
end