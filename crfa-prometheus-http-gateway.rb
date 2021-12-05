require 'webrick'
require 'faraday'
require 'json'

server = WEBrick::HTTPServer.new(:Port => 8082,
                             :SSLEnable => false)

host_port = ARGV[0]

def filterMetrics(body)
    obj = { }

    body.each_line { | line | 
        if line.start_with?('node_directory_size_bytes')
            split = line.gsub(/\s+/m, ' ').strip.split(" ")

            obj = { :cardanoDbSize => split[1].strip}
        end
    }

    return obj.to_json
end

server.mount_proc '/cardano-metrics' do |req, res|
    url = "#{host_port}/metrics"
    response = Faraday.get(url)

    res.body = filterMetrics(response.body)
end

trap 'INT' do server.shutdown end

server.start