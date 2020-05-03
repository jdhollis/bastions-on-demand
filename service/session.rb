require 'bundler'
Bundler.require

require 'json'
require 'net/http'
require 'uri'

INVOKE_URL = ENV['INVOKE_URL']
REGION = URI.parse(INVOKE_URL).host.split('.')[2]

BASE_HEADERS = {
    'Content-Type' => 'application/json',
    'Accept' => 'application/json'
}

def perform(action)
  uri = URI.parse("#{INVOKE_URL}/bastion")

  method = case action
           when :create
             'POST'
           when :destroy
             'DELETE'
           end

  signer = Aws::Sigv4::Signer.new(
      service: 'execute-api',
      region: REGION,
      credentials_provider: Aws::SharedCredentials.new
  )

  signature = signer.sign_request(
      http_method: method,
      url: uri.to_s,
      headers: BASE_HEADERS
  )

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  action_request = case method
                   when 'POST'
                     Net::HTTP::Post.new(uri)
                   when 'DELETE'
                     Net::HTTP::Delete.new(uri)
                   end

  BASE_HEADERS.merge(signature.headers).each { |k, v|
    action_request[k] = v
  }

  action_request['accept-encoding'] = nil
  action_request['user-agent'] = nil

  response = http.request(action_request)

  if response.code == '201'
    puts "#{JSON.pretty_generate(JSON.parse(response.body))}"
  end
end
