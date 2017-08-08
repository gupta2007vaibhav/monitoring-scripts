#!/usr/bin/env ruby
require 'whois'
require 'whois-parser'
require 'date'
require 'date'
require 'yaml'
require 'riemann/client'

class Domain

  def initialize
    @c = Riemann::Client.new host: 'x.x.x.x', port: 5555, timeout: 60
  end

  def dns(whs)
    while true
      results = YAML.load_file('config.yml')
      results['domains'].each do |domain|
        sleep 2
        r = whs.lookup(domain)
        expire = r.parser.expires_on.strftime("%Y-%m-%d")
        today = Time.now.strftime("%Y-%m-%d")
        expire_date = DateTime.parse(expire)
        today_date = DateTime.parse(today)
        difference_in_days = (expire_date - today_date).to_i
        if difference_in_days > 30
          @c << { metric: "#{difference_in_days}" , ttl: 600, service: "#{domain}", state: 'ok',  domain: domain, host: 'domain', tags: ['persistent-stat'] }
          puts "#{difference_in_days} to expire #{domain}"
        else
          @c << { metric: "#{difference_in_days}" , ttl: 600, service: "#{domain}", state: 'warning',  domain: domain, host: 'domain', tags: ['persistent-stat'] }
          puts "#{difference_in_days} to expire #{domain}"
        end
      end
    end
  end
end

def main()
  dns_expire = Domain.new()
  whs = Whois::Client.new(timeout: 30)
  dns_expire.dns(whs)
end

main
