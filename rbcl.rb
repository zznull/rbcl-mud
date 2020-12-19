#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

$: << File.expand_path(File.dirname(__FILE__))

require 'gtk3'
require 'lib/gtk3/main_window'

module RbCl
  module UI
    class Application
      def initialize
        super

        @main_window = MainWindow.new(self)
        if $ARGV.count == 1
          begin
            @client = Client::load($ARGV[0], @main_window.client_widget)
          rescue Errno::ENOENT
            puts "File not found: #{$ARGV[0]}"
            exit 1
          end
        else
          @client = Client.new(@main_window.client_widget)
        end

      rescue Gio::ResolverError::NotFound
        puts "Could not resolve address"
        exit 1
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
