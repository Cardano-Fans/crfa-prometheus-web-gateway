require 'webrick'
require 'faraday'
require 'json'

server = WEBrick::HTTPServer.new(:Port => 8082,
                             :SSLEnable => false)

# node metrics                             
node_host_port = ARGV[0]
# cardano node metrics
cardano_node_host_port = ARGV[1]

puts "node_host_port:" + node_host_port
puts "cardano_node_host_port:" + cardano_node_host_port

def filterMetrics(body)
    obj = { }

    body.each_line { | line | 
        if line.start_with?('node_directory_size_bytes')
            split = line.gsub(/\s+/m, ' ').strip.split(" ")

            obj[:cardanoDbSize] = split[1].strip
        end
        if line.start_with?('cardano_node_metrics_density_real')
            split = line.gsub(/\s+/m, ' ').strip.split(" ")

            obj[:chainDensity] = split[1].strip
        end
    }

    return obj.to_json
end

server.mount_proc '/cardano-metrics' do |req, res|
    node_url = "#{node_host_port}/metrics"
    node_response = Faraday.get(node_url)

    cardano_node_url = "#{cardano_node_host_port}/metrics"
    cardano_node_response = Faraday.get(cardano_node_url)

    combined = node_response.body + "\n" + cardano_node_response.body

    puts combined

    res.body = filterMetrics(combined)
end

trap 'INT' do server.shutdown end

server.start