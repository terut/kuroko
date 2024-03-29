require 'kage'
require 'diff/lcs'

def compare(a, b)
  diffs = Diff::LCS.diff(a.split(/\n/), b.split(/\n/))
  diffs.each do |diff|
    diff.each do |line|
      p line
    end 
  end 
end

Kage::ProxyServer.start do |server|
  server.port = 8090
  server.host = '0.0.0.0'
  server.debug = false

  # backends can share the same host/port
  server.add_master_backend(:production, '192.168.33.10', 8080)
  server.add_backend(:sandbox, '192.168.33.11', 8080)

  server.client_timeout = 15
  server.backend_timeout = 10

  # Dispatch all GET requests to multiple backends, otherwise only :production
  server.on_select_backends do |request, headers|
    if request[:method] == 'GET'
      [:production, :sandbox]
    else
      [:production]
    end 
  end 

  # Add optional headers
  server.on_munge_headers do |backend, headers|
    #headers['X-Kage-Session'] = self.session_id
    #headers['X-Kage-Sandbox'] = 1 if backend == :sandbox
  end 

  # This callback is only fired when there are multiple backends to respond
  server.on_backends_finished do |backends, requests, responses|
    compare(responses[:production][:data], responses[:sandbox][:data])
  end 

  puts "Starting on port #{server.port}"
end
