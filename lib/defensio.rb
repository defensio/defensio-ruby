#
#  Defensio-Ruby version 0.1
#  Written by the Defensio team at Websense, Inc.
#
#  Make sure to install the necessary gems by running the following commands:
#  $ sudo gem install patron -v 0.4.4
#  On Linux, you'll also need to install the libcurl development package. On Ubuntu, simply do:
#  $ sudo apt-get install libcurl4-openssl-dev
#

require 'rubygems'
require 'patron'
require 'uri'

class Defensio
  # You shouldn't modify these values unless you really know what you are doing. And then again...
  API_VERSION   = 2.0
  API_HOST      = "http://api.defensio.com"

  # You should't modify anything below this line.
  LIB_VERSION   = "0.1"
  ROOT_NODE     = "defensio-result"
  FORMAT        = :yaml
  USER_AGENT    = "Defensio-Ruby #{LIB_VERSION}"
  CLIENT        = "Defensio-Ruby | #{LIB_VERSION} | Carl Mercier | cmercier@websense.com"
  KEEP_ALIVE    = false
  
  attr_reader :http_session, :client
  
  def initialize(api_key, client = CLIENT)
    @client = client
    @api_key = api_key
  end

  # Get information about the api key
  def get_user
    call :get, api_url
  end
  
  # Create and analyze a new document
  # @param [Hash] data The parameters to be sent to Defensio. Keys can either be Strings or Symbols
  # @return [Array] An array containing 2 values: the HTTP status code & a Hash with the values returned by Defensio
  def post_document(data)
    data = { :client => @client }.merge(data)
    call :post, api_url("documents"), data
  end
  
  # Get the status of an existing document
  # @param [String] signature The signature of the document to retrieve
  # @return [Array] An array containing 2 values: the HTTP status code & a Hash with the values returned by Defensio
  def get_document(signature)
    call :get, api_url("documents", signature)
  end
  
  # Modify the properties of an existing document
  # @param [String] signature The signature of the document to modify
  # @param [Hash] data The parameters to be sent to Defensio. Keys can either be Strings or Symbols
  # @return [Array] An array containing 2 values: the HTTP status code & a Hash with the values returned by Defensio
  def put_document(signature, data)
    call :put, api_url("documents", signature), data
  end
  
  # Get basic statistics for the current user
  # @return [Array] An array containing 2 values: the HTTP status code & a Hash with the values returned by Defensio
  def get_basic_stats
    call :get, api_url("basic-stats")
  end

  # Get more exhaustive statistics for the current user
  # @param [Hash] data The parameters to be sent to Defensio. Keys can either be Strings or Symbols
  # @return [Array] An array containing 2 values: the HTTP status code & a Hash with the values returned by Defensio
  def get_extended_stats(data)
    result = call(:get, api_url("extended-stats"), data)
    0.upto(result[1]["data"].size - 1) do |i|
      result[1]["data"][i]["date"] = Date.parse(result[1]["data"][i]["date"])
    end
      
    result
  end

  # Filter a set of values based on a pre-defined dictionary
  def post_dictionary_filter(data)
    call :post, api_url("dictionary-filter"), data
  end
  
  # Takes the request object (Rails, Sinatra, Merb) of an async request callback and returns a hash
  # containing the status of the document being analyzed.
  # @param [ActionController::Request, Sinatra::Request, String] request The request object created after Defensio POSTed to your site, or a string representation of the POST data.
  # @return [Hash] Status of the document
  def handle_post_document_async_callback(request)
    if request.is_a?(String)
      data = request
    elsif request.respond_to?(:body) && request.body.is_a?(StringIO)
      data = request.body.read
    else
      raise ArgumentError, "Unknown request type: #{request.class}"
    end

    parse_body(data)
  end
  
  # See handle_post_document_async_callback
  def self.handle_post_document_async_callback(request)
    Defensio.new(nil).handle_post_document_async_callback(request)
  end

  protected
    def api_url(action = nil, id = nil)
      path = "#{API_HOST}/#{API_VERSION}/users/#{@api_key}"
      path += "/#{action}" if action
      path += "/#{id}" if id
      path += ".#{FORMAT}"
    end
  
    def http_session
      return @http_session if KEEP_ALIVE && @http_session
      @http_session = Patron::Session.new
      @http_session.timeout = 20
      @http_session.headers['User-Agent'] = USER_AGENT
      @http_session.headers['Content-Type'] = "text/#{FORMAT}"
      @http_session
    end

    def http_session=(session)
      @http_session = session
    end
    
    def call(method, url, data = nil)
      data = hash_to_query_string(data) if data.is_a?(Hash)
      url = url + "?#{data}" unless data.nil? || data.empty?

      response = case method
      when :get
        http_session.get(url)
      when :delete
        http_session.delete(url)
      when :post
        http_session.post(url, {})
      when :put
        http_session.put(url, {})
      else
        raise(ArgumentError, "Invalid HTTP method: #{method}")
      end
      
      http_session = nil unless KEEP_ALIVE
      
      [response.status, parse_body(response.body)]
    end

    def parse_body(str)
      if FORMAT == :yaml
        return YAML::load(str)[ROOT_NODE]
      else
        raise(NotImplementedError, "This library doesn't support this format: #{FORMAT}")
      end
    end

    def hash_to_query_string(data)
      return nil unless data.is_a?(Hash)
      out = ""
      sort_hash_by_key(data).each do |item|
        k, v = item[0], item[1]
        out += "&" unless out.empty?
        k = k.to_s.gsub(/_/, "-") if k.is_a?(Symbol)
        out += "#{k}=#{URI.escape(v.to_s)}"
      end
      out
    end

    def sort_hash_by_key(hash)
      hash.keys.sort_by {|s| s.to_s}.map {|key| [key, hash[key]] }
    end
end
