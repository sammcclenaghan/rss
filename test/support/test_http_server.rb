require "socket"

# A minimal, real HTTP server bound to a random loopback port. Routes are
# programmed per-path. Used to exercise the real RestrictedHTTP::Client over an
# actual TCP socket (a real server, not a stub).
class TestHTTPServer
  Route = Struct.new(:status, :headers, :body)

  STATUS_TEXT = { 200 => "OK", 302 => "Found", 404 => "Not Found" }.freeze

  def initialize
    @routes = {}
    @server = TCPServer.new("127.0.0.1", 0)
    @thread = Thread.new { serve }
  end

  def host = "127.0.0.1"
  def port = @server.addr[1]

  def url_for(path)
    "http://#{host}:#{port}#{path}"
  end

  def on(path, status: 200, headers: {}, body: "")
    @routes[path] = Route.new(status, headers, body)
    self
  end

  def shutdown
    @thread.kill
    @server.close unless @server.closed?
  end

  private
    def serve
      loop do
        client = @server.accept
        handle(client)
        client.close
      end
    rescue IOError, Errno::EBADF
      # Server shutting down.
    end

    def handle(client)
      request_line = client.gets or return
      path = request_line.split(" ")[1]
      while (line = client.gets) && line != "\r\n"; end # drain request headers

      write(client, @routes.fetch(path, Route.new(404, {}, "")))
    end

    def write(client, route)
      headers = { "Content-Length" => route.body.bytesize, "Connection" => "close" }.merge(route.headers)

      client.write("HTTP/1.1 #{route.status} #{STATUS_TEXT.fetch(route.status, "OK")}\r\n")
      headers.each { |name, value| client.write("#{name}: #{value}\r\n") }
      client.write("\r\n")
      client.write(route.body)
    end
end
