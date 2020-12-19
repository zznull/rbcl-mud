require 'pry'

require 'lib/gtk3/output_widget'
require 'lib/gtk3/css_support'

module RbCl
  module UI
    class MultipleOutputWidget < Gtk::Notebook
      include CssSupport

      def initialize
        super

        @output_widgets = {}
        @output_widgets_array = []
        @output_widget_labels = {}
        @scrolled_back = {}

        set_name('multiple-output-widget')
        load_css

        @main_output_widget = create_output_widget('main')
        @debug_output_widget = create_output_widget('debug')

        signal_connect('switch-page') { |widget, _, page_num| tab_switched(page_num) }

        GLib::Timeout.add_seconds(1) { check_resized }
      end

      def create_output_widget name
        return if @output_widgets[name]

        output_widget = OutputWidget.new
        add_css_provider(output_widget.style_context)
        output_widget.show

        output_scrolled_window = Gtk::ScrolledWindow.new
        output_scrolled_window.set_name('output-widget-container')
        add_css_provider(output_scrolled_window.style_context)
        output_scrolled_window.set_policy(Gtk::PolicyType::NEVER, Gtk::PolicyType::ALWAYS)

        output_scrolled_window.signal_connect('scroll-event') do |widget|
          scrolled(output_widget)
        end

        output_scrolled_window.signal_connect('edge-reached') do |widget, pos|
          scroll_edge_reached(output_widget, pos)
        end

        # scroll to bottom unless scrolled back
        vadjustment_upper = output_scrolled_window.vadjustment.upper
        output_scrolled_window.vadjustment.signal_connect('changed') do |adjustment|
          if vadjustment_upper != adjustment.upper && !@scrolled_back[output_widget]
            adjustment.value = adjustment.upper
            output_widget.queue_draw
          end
          vadjustment_upper = adjustment.upper
        end

        output_scrolled_window.add(output_widget)
        output_scrolled_window.show

        @output_widgets[name] = output_widget
        @output_widgets_array << output_widget

        label = Gtk::Label.new(name)
        @output_widget_labels[output_widget] = label
        append_page(output_scrolled_window, label)

        output_widget
      end

      def window_size
        visible_rect = @main_output_widget.visible_rect

        char_width, char_height = @main_output_widget.char_size

        cols = visible_rect.width / char_width
        rows = visible_rect.height / char_height

        [cols, rows]
      end

      def print(text, window_name = 'main')
        if @output_widgets[window_name].nil?
          create_output_widget(window_name)
        end

        output_widget = @output_widgets[window_name]
        
        if @output_widgets_array[page] != output_widget # if printing to a widget that is not currently visible
          # label = get_tab_label(output_widget) # returns ni, though label was specified
          label = @output_widget_labels[output_widget]
          label.markup = '<span weight="bold">' + window_name + '</span>'
        end

        # if window_name == 'debug'
        #   label = get_tab_label(@output_widgets[window_name])
        #   label.markup = '<span weight="bold">' + window_name + '</span>'
        # end

        output_widget.print(text)

        # unless @scrolled_back[output_widget]
        #   puts 'scrolling to bottom'
        #   # output_widget.scroll_to_bottom
        #   output_widget.parent.vadjustment.value = output_widget.parent.vadjustment.upper
        #   output_widget.queue_draw
        # end
      end

      def on_resized(&block)
        @resized_callback = block
      end

      def on_tab_switch(&block)
        @on_tab_switch = block
      end

      protected

      # sets @scrolled_back to true when @output_scrolled_window not scrolled to very bottom
      def scrolled(output_widget)
        if output_widget.parent.vadjustment.value + output_widget.parent.vadjustment.page_size < output_widget.parent.vadjustment.upper
          @scrolled_back[output_widget] = true
          output_widget.keep_scrollback = true
        end

        false
      end

      # sets @scrolled_back to false when @output_scrolled_window is scrolled to very bottom
      def scroll_edge_reached(output_widget, pos)
        if pos == Gtk::PositionType::BOTTOM
          @scrolled_back[output_widget] = false
          output_widget.keep_scrollback = false
        end

        false
      end

      # runs periodically and calls client.window_resized when window resized
      def check_resized
        rect = @main_output_widget.visible_rect

        unless @output_scrolled_window_visible_rect.nil?
          if @output_scrolled_window_visible_rect.width != rect.width || @output_scrolled_window_visible_rect.height != rect.height
            @resized_callback.call(window_size) if @resized_callback
          end
        end

        @output_scrolled_window_visible_rect = @main_output_widget.visible_rect

        true # return true to signal handler
      end

      def tab_switched(page_num)
        output_widget = @output_widgets_array[page_num]
        name = @output_widgets.rassoc(output_widget)[0]
        @output_widget_labels[output_widget].markup = name
        
        @on_tab_switch.call if @on_tab_switch
      end
    end
  end
end
