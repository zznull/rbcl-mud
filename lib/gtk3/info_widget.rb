require 'rbcl/lib/gtk3/css_support'
require 'rbcl/lib/gtk3/progress_bar'
require 'rbcl/lib/gtk3/output_widget'

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

        @room_name_label = Gtk::Label.new
        add_css_provider(@room_name_label.style_context)
        @room_name_label.style_context.add_class('info')
        @room_name_label.name = 'room'
        pack_start(@room_name_label)

        @map_widget = OutputWidget.new
        add_css_provider(@map_widget.style_context)
        @map_widget.style_context.add_class('map')
        pack_start(@map_widget)
      end

      def char_base=(base)
        @name_label.text = base['name']
        @name_label.show
        @class_label.text = base['class'] + ' (Lvl ' + base['level'].to_s + ')'
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

      def char_vitals=(vitals)
        @health_progress_bar.value = vitals['hp'] if vitals['hp']
        @mana_progress_bar.value = vitals['mana'] if vitals['mana']
        @moves_progress_bar.value = vitals['moves'] if vitals['moves']
      end

      def char_maxstats=(maxstats)
        @health_progress_bar.max = maxstats['maxhp'] if maxstats['maxhp']
        @mana_progress_bar.max = maxstats['maxmana'] if maxstats['maxmana']
        @moves_progress_bar.max = maxstats['maxmoves'] if maxstats['maxmoves']
      end

      def map_text=(text)
        @map_widget.clear
        @map_widget.print(text)
        @map_widget.show
      end

      def room_info=(data)
        @room_name_label.text = data['name']
        @room_name_label.show
      end
    end
  end
end