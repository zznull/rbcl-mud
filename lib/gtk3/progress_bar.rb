require 'lib/gtk3/css_support'

module RbCl
  module UI
    class ProgressBar < Gtk::Overlay
      include CssSupport

      def initialize(css_class, color)
        super()

        set_name 'dbg'

        load_css

        @progress_bar = Gtk::ProgressBar.new
        @progress_bar.style_context.add_class(css_class)
        add_css_provider(@progress_bar.style_context)

        bg_css_provider = Gtk::CssProvider.new
        bg_css_provider.load_from_data("progressbar progress { background-color: #{color}; }")
        @progress_bar.style_context.add_provider(bg_css_provider, 800)

        @progress_bar.show

        add(@progress_bar)

        @label = Gtk::Label.new
        @label.style_context.add_class('progress-bar')
        add_css_provider(@label.style_context)

        @label.show

        add_overlay(@label)
      end

      def value=(val)
        @value = val.dup.to_i
        update
      end

      def max=(val)
        @max = val.dup.to_i
        update
      end

      protected

      def update
        if !@value.nil? && !@max.nil? && @max > 0
          @progress_bar.fraction = @value.to_f / @max
          @label.text = @value.to_s + '/' + @max.to_s
          show
        end
      end
    end
  end
end