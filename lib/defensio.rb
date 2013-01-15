#
#  Defensio-Ruby
#  Written by the Defensio team at Websense, Inc.
#

require 'rubygems'
require 'httparty'
require 'uri'
require 'multi_json'

class Defensio
  # You shouldn't modify these values unless you really know what you are doing. And then again...
  API_VERSION   = 2.0
  API_HOST      = "http://api.defensio.com"

  # You should't modify anything below this line.
  LIB_VERSION   = "0.9.1"
  ROOT_NODE     = "defensio-result"
  FORMAT        = :json
  USER_AGENT    = "Defensio-Ruby #{LIB_VERSION}"
  CLIENT        = "Defensio-Ruby | #{LIB_VERSION} | Carl Mercier | cmercier@websense.com"
  KEEP_ALIVE    = false
  
  include HTTParty
  format FORMAT
  base_uri API_HOST
  
  attr_reader :api_key, :client
  
  def initialize(api_key, client = CLIENT)
    @client = client
    @api_key = api_key
  end

  # Get information about the api key
  def get_user
    respond self.class.get(api_path)
  end
  
  # Create and analyze a new document
  # @param [Hash] data The parameters to be sent to Defensio. Keys can either be Strings or Symbols
  # @return [Array] An array containing 2 values: the HTTP status code & a Hash with the values returned by Defensio
  def post_document(data)
    data = { :client => @client }.merge(data)
    respond self.class.post(api_path("documents"), :body => data)
  end
  
  # Get the status of an existing document
  # @param [String] signature The signature of the document to retrieve
  # @return [Array] An array containing 2 values: the HTTP status code & a Hash with the values returned by Defensio
  def get_document(signature)
    respond self.class.get(api_path("documents", signature))
  end
  
  # Modify the properties of an existing document
  # @param [String] signature The signature of the document to modify
  # @param [Hash] data The parameters to be sent to Defensio. Keys can either be Strings or Symbols
  # @return [Array] An array containing 2 values: the HTTP status code & a Hash with the values returned by Defensio
  def put_document(signature, data)
    respond self.class.put(api_path("documents", signature), :body => data)
  end
  
  # Get basic statistics for the current user
  # @return [Array] An array containing 2 values: the HTTP status code & a Hash with the values returned by Defensio
  def get_basic_stats
    respond self.class.get(api_path("basic-stats"))
  end

  # Get more exhaustive statistics for the current user
  # @param [Hash] data The parameters to be sent to Defensio. Keys can either be Strings or Symbols
  # @return [Array] An array containing 2 values: the HTTP status code & a Hash with the values returned by Defensio
  def get_extended_stats(data)
    result = self.class.get(api_path("extended-stats"), :query => data)
    code = result.code
    result = result[ROOT_NODE]

    0.upto(result["data"].size - 1) do |i|
      result["data"][i]["date"] = Date.parse(result["data"][i]["date"])
    end
      
    [code, result]
  end

  # Filter a set of values based on a pre-defined dictionary
  def post_profanity_filter(data)
    respond self.class.post(api_path("profanity-filter"), :body => data)
  end
  
  # Takes the request object (Rails, Sinatra, Merb) of an async request callback and returns a hash
  # containing the status of the document being analyzed.
  # @param [ActionController::Request, Sinatra::Request, String] request The request object created after Defensio POSTed to your site, or a string representation of the POST data.
  # @return [Hash] Status of the document
  def handle_post_document_async_callback(request)
    if request.is_a?(String)
      data = request
    elsif request.respond_to?(:body) && request.body.respond_to?(:read)
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
    def respond(response)
      [response.code, response[ROOT_NODE]]
    end
    
    def api_path(action = nil, id = nil)
      path = "/#{API_VERSION}/users/#{@api_key}"
      path += "/#{action}" if action
      path += "/#{id}" if id
      path += ".#{FORMAT}"
    end

    def parse_body(str)
      if FORMAT == :json
        return MultiJson.load(str)[ROOT_NODE]
      else
        raise(NotImplementedError, "This library doesn't support this format: #{FORMAT}")
      end
    end

end
