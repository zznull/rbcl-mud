require 'rbcl/lib/gtk3/css_support'

module RbCl
  module UI
    class ProgressBar < Gtk::Overlay
      include CssSupport

      def initialize(css_class)
        super()

        set_name 'dbg'

        load_css

        @progress_bar = Gtk::ProgressBar.new
        @progress_bar.style_context.add_class(css_class)
        @progress_bar.style_context.add_provider(css_provider, 800)
        @progress_bar.show

        add(@progress_bar)

        @label = Gtk::Label.new
        @label.style_context.add_class('progress-bar')
        @label.style_context.add_provider(css_provider, 800)
        @label.show

        add_overlay(@label)
      end

      def value=(val)
        @value = val.dup
        update
      end

      def max=(val)
        @max = val.dup
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