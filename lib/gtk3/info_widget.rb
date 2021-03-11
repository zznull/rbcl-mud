require 'lib/gtk3/css_support'
require 'lib/gtk3/progress_bar'
require 'lib/gtk3/output_widget'

module RbCl
  module UI
    class InfoWidget < Gtk::Box
      include CssSupport

      def initialize()
        super(:vertical)

        set_name('info-widget')
        load_css

        @name_label = Gtk::Label.new
        add_css_provider(@name_label.style_context)
        @name_label.style_context.add_class('name')
        pack_start(@name_label)

        @class_label = Gtk::Label.new
        add_css_provider(@class_label.style_context)
        @class_label.style_context.add_class('class')
        pack_start(@class_label)

        @health_progress_bar = ProgressBar.new('health')
        @mana_progress_bar = ProgressBar.new('mana')
        @moves_progress_bar = ProgressBar.new('moves')
        @exp_progress_bar = ProgressBar.new('exp')

        pack_start(@health_progress_bar)
        pack_start(@mana_progress_bar)
        pack_start(@moves_progress_bar)
        pack_start(@exp_progress_bar)

        @labels = {}
        @labels_box = Gtk::Box.new(:vertical)
        @labels_box.show
        pack_start(@labels_box)

        @map_widget = OutputWidget.new
        add_css_provider(@map_widget.style_context)
        @map_widget.style_context.add_class('map')
        pack_start(@map_widget)
      end

      def char_name=(name)
        @name_label.text = name
        @name_label.show
      end

      def set_char_class_level(class_name, level)
        @class_label.text = class_name + ' ' + level.to_s
        @class_label.show
      end

      def add_label(name)
        label = Gtk::Label.new
        add_css_provider(label.style_context)
        label.style_context.add_class('info')
        label.xalign = 0
        @labels[name] = label
        @labels_box.pack_start(label)
      end

      def set_label(name, value)
        if @labels[name]
          @labels[name].markup = value
          @labels[name].show
        end
      end

      def set_health(hp, maxhp)
        @health_progress_bar.value = hp.to_i
        @health_progress_bar.max = maxhp.to_i
      end

      def set_mana(mp, maxmp)
        @mana_progress_bar.value = mp.to_i
        @mana_progress_bar.max = maxmp.to_i
      end

      def set_moves(ep, maxep)
        @moves_progress_bar.value = ep.to_i
        @moves_progress_bar.max = maxep.to_i
      end

      def set_exp(exp, tnl)
        @exp_progress_bar.value = exp.to_i
        @exp_progress_bar.max = tnl.to_i
      end

      def map_text=(text)
        @map_widget.clear
        @map_widget.print(text)
        @map_widget.show
      end

      def room_info=(data)
      end
    end
  end
end