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
        @name_label.style_context.add_provider(css_provider, 800)
        @name_label.style_context.add_class('name')
        pack_start(@name_label)

        @class_label = Gtk::Label.new
        @class_label.style_context.add_provider(css_provider, 800)
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

        @exp_label = Gtk::Label.new
        @exp_label.style_context.add_provider(css_provider, 800)
        @exp_label.style_context.add_class('info')
        @exp_label.style_context.add_class('exp')
        @exp_label.xalign = 0
        pack_start(@exp_label)

        @gold_label = Gtk::Label.new
        @gold_label.style_context.add_provider(css_provider, 800)
        @gold_label.style_context.add_class('info')
        @gold_label.style_context.add_class('gold')
        @gold_label.xalign = 0
        pack_start(@gold_label)

        @room_name_label = Gtk::Label.new
        @room_name_label.style_context.add_provider(css_provider, 800)
        @room_name_label.style_context.add_class('info')
        @room_name_label.style_context.add_class('room-name')
        pack_start(@room_name_label)

        @map_widget = OutputWidget.new
        @map_widget.style_context.add_provider(css_provider, 800)
        @map_widget.style_context.add_class('map')
        pack_start(@map_widget)
      end

      def char_base=(base)
        @name_label.text = base['name']
        @name_label.show
        @class_label.text = base['class'] + ' (Lvl ' + base['level'].to_s + ')'
        @class_label.show
      end

      def char_status=(status)
        @exp_label.markup = "Exp tnl: <span weight=\"bold\">#{status['tnl']}</span>"
        @exp_label.show
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

      def char_worth=(worth)
        @gold_label.markup = "Gold: <span weight=\"bold\" color=\"gold\">#{worth['gold']}</span> (bank: #{worth['bank']})"
        @gold_label.show
      end

      def char_exp=(exp)
        @exp_progress_bar.value = exp
      end

      def char_max_exp=(max_exp)
        @exp_progress_bar.max = max_exp
      end

      def room_info=(info)
        # @room_name_label.text = info['name']
        # @room_name_label.show

        # @exits_box.children.each { |child| @exits_box.remove(child) }
        # info['exits'].each_pair do ||
        # end
      end

      def map_text=(text)
        @map_widget.clear
        @map_widget.print(text)
        @map_widget.show
      end

      protected

      def add_room_label(exit, name)
        label = Gtk::Label.new
        label.style_context.add_provider(css_provider, 800)
        label.style_context.add_class('info')
        label.style_context.add_class('exit')
        label.xalign = 0 
        @exits_box.pack_start(label)
      end
    end
  end
end