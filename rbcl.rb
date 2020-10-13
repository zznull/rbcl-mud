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
        @client = Client.new(@main_window.client_widget)

        if $ARGV[0]
          port = 23
          port = $ARGV[1].to_i if $ARGV[1] && $ARGV[1] =~ /\A\d+\Z/
          @client.connect($ARGV[0], port)
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
