require "chef"
require "chef/handler"
require "net/http"
require "json"

class ApiEndpointHandler < Chef::Handler
  attr_writer :endpoint_host, :endpoint_port, :path, :use_ssl, :public_key, :secret_key

  def initialize(options = {})
    @endpoint_host = "api.example.com"
    @endpoint_port = "8080"
    @path          = "/chef"
    @use_ssl       = false
    @public_key    = ""
    @secret_key    = ""

    if @endpoint_port == "80" or @endpoint_port == "443"
      @host = "{@endpoint_host}"
    else
      @host = "#{@endpoint_host}:#{@endpoint_port}"
    end

  end

  def report
    Chef::Log.debug("ApiEndpointHandler loaded as a handler")

    #Hash useful stats.
    metrics = Hash.new
    # Node information
    metrics[:hostname] = node[:hostname]
    metrics[:runcontext] = run_status.run_context
    # Resource Info
    metrics[:updated_resources] = run_status.updated_resources
    metrics[:updated_resources_length] = run_status.updated_resources.length
    metrics[:all_resources] = run_status.all_resources
    metrics[:all_resources_length] = run_status.all_resources.length
    # Time
    metrics[:start_time] = run_status.start_time
    metrics[:end_time] = run_status.end_time
    metrics[:elapsed_time] = run_status.elapsed_time
    # Status of run
    metrics[:success] = run_status.success?
    metrics[:failed] = run_status.failed?
    # Exceptions and Backtrace
    metrics[:exception] = run_status.exception
    metrics[:backtrace] = run_status.backtrace


    uri = URI('#{@http_type}://#{@host}#{@path}')
    request = Net::HTTP::Post.new uri.path
    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    request.basic_auth @public_key, @secret_key
    request.body = metrics.to_json

    response = Net::HTTP.start(uri.host, uri.port, :use_ssl => @use_ssl) do |http|
      if @use_ssl
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.ssl_version = :SSLv3
      end
      http.request request
    end

    puts response

    json = JSON.parse response.body

    Chef::Log.debug(json['errorcode'])
  end
end