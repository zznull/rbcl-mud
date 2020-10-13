require 'gio2'

module RbCl
  class Connection
    def initialize(host, port, client)
      @client = client
      connect host, port
    end

    def connect(host, port)
      @socket_client = Gio::SocketClient.new
      @socket_connection = @socket_client.connect(Gio::NetworkAddress.new host, port)
      fd = @socket_connection.socket.fd

      @io_channel = GLib::IOChannel.new(fd)
      @io_channel.set_encoding(nil)
      @io_channel.add_watch(GLib::IOChannel::IN | GLib::IOChannel::HUP) { read }

      true
    rescue Gio::IOError::ConnectionRefused
      @client.process "Connection refused"
    end

    def disconnect
      @io_channel.close
      @client.connection_closed
    end

    def write data
      # @io_channel.write data
      # @io_channel.flush
      @socket_connection.socket.send(data)
    end

    private

    def read
      unless @on_connected_notified
        @on_connected_notified = true
        @client.connection_opened
      end

      loop do
        data = @io_channel.read(16384).force_encoding(Encoding::ASCII_8BIT)

        if data.length == 0
          @io_channel.close
          @client.connection_closed
          return false
        else
          process data
        end

        break true if data.length < 16384
      end
    end
  end

  def process
  end
end
