#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

$: << File.expand_path(File.dirname(__FILE__) + "/../")

require 'gtk3'
require 'rbcl/lib/gtk3/main_window'

module RbCl
  module UI
    class Application
      def initialize
        super

        @main_window = MainWindow.new(self)
        if $ARGV.count == 1
          @client = Client::load($ARGV[0], @main_window.client_widget)
        else
          @client = Client.new(@main_window.client_widget)
        end
      end

      def run
        Signal.trap('INT') { quit }
        Gtk.main #_with_queue 100
      end

      def quit
        # TODO: check if main loop is running
        Gtk.main_quit
      end
    end
  end
end

RbCl::UI::Application.new.run
