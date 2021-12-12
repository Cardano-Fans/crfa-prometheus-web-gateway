require 'webrick'
require 'faraday'
require 'json'

server = WEBrick::HTTPServer.new(:Port => 8082,
                             :SSLEnable => false)

puts "Configured urls:"
ARGV.each { |url| puts url }

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
        if line.start_with?('cardano_node_metrics_utxoSize_int')
            split = line.gsub(/\s+/m, ' ').strip.split(" ")

            obj[:utxoSize] = split[1].strip
        end
        if line.start_with?('cardano_node_metrics_delegMapSize_int')
            split = line.gsub(/\s+/m, ' ').strip.split(" ")

            obj[:delegMapSize] = split[1].strip
        end
    }

    return obj.to_json
end

server.mount_proc '/cardano-metrics' do |req, res|
    combined = ""
    ARGV.each { |base_url| 
        puts base_url
        url = "#{base_url}/metrics"
        response = Faraday.get(url)
        body = response.body

        combined += body + "\n"
    }

    res.body = filterMetrics(combined)
end

trap 'INT' do server.shutdown end

server.start