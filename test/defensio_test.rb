DEFENSIO_ENV = "test"

require File.dirname(__FILE__) + "/../lib/defensio"
require 'test/unit'
require 'mocha'
require 'ostruct'

# You must run this script as following:
# $ DEFENSIO_KEY=<your api key here> ruby test/defensio_test.rb

class DefensioTest < Test::Unit::TestCase
  API_HOST    = "http://api.defensio.com"
  API_VERSION = 2.0
  OWNER_URL   = "http://example.org"
  FORMAT      = :json
  HEADERS     = {"User-Agent" => "Defensio-Ruby #{Defensio::LIB_VERSION}", "Content-Type" => "text/json"}

  # API METHOD TESTS -- Useful to learn how to use the library
  def test_get_user
    status, body = @d.get_user
    assert body.is_a?(Hash)
    assert_equal 200, status
    assert_equal "success", body["status"]
  end

  def test_post_get_put_document
    # POST
    data = { :content => "This is a simple test", :platform => "my_awesome_app", :type => "comment" }
    status, body = @d.post_document(data)
    assert body.is_a?(Hash)
    assert_equal 200, status
    assert_equal "success", body["status"]
    assert body["signature"].is_a?(String)

    # Keep some variables around
    original_allow_result = body["allow"]
    signature = body["signature"]

    # Give Defensio some time to process
    sleep 0.5

    # GET
    status, body = @d.get_document(signature)
    assert body.is_a?(Hash)
    assert_equal 200, status
    assert_equal "success", body["status"]
    assert_equal signature, body["signature"]

    # PUT
    status, body = @d.put_document(signature, :allow => !original_allow_result)
    assert body.is_a?(Hash)
    assert_equal 200, status
    assert_equal "success", body["status"]
    assert_equal signature, body["signature"]
    assert_equal !original_allow_result, body["allow"]

    # PUT (back to original value)
    status, body = @d.put_document(signature, :allow => original_allow_result)
    assert body.is_a?(Hash)
    assert_equal 200, status
    assert_equal "success", body["status"]
    assert_equal signature, body["signature"]
    assert_equal original_allow_result, body["allow"]
  end
  
  def test_get_basic_stats
    status, body = @d.get_basic_stats
    assert body.is_a?(Hash)
    assert_equal 200, status
    assert_equal "success", body["status"]
    assert body["unwanted"]["total"].is_a?(Integer)
  end

  def test_get_extended_stats
    status, body = @d.get_extended_stats(:from => Date.new(2009, 9, 1), :to => Date.new(2009, 9, 3))
    assert body.is_a?(Hash)
    assert_equal 200, status
    assert_equal "success", body["status"]
    assert body["data"].is_a?(Array)
    assert body["data"][0]["date"].is_a?(Date)  if body["data"].size > 0
  end
  
  def test_post_profanity_filter
    status, body = @d.post_profanity_filter("field1"=>"hello world", "other_field"=>"hello again")
    assert body.is_a?(Hash)
    assert_equal 200, status
    assert_equal "success", body["status"]
    assert body["filtered"].is_a?(Hash)
    assert body["filtered"].keys.include?("field1")
    assert body["filtered"].keys.include?("other_field") 
  end
  
  def test_handle_post_document_async_callback__string
    result = { "defensio-result" =>
               { "api-version"       => API_VERSION, 
                 "status"            => "success", 
                 "message"           => nil, 
                 "signature"         => "123456",
                 "allow"             => false,
                 "classification"    => "malicious",
                 "spaminess"         => 0.95,
                 "profanity-match"  => true }
              }
    
    assert_equal Hash, @d.class.handle_post_document_async_callback(result.to_json).class
  end

  def test_handle_post_document_async_callback__request_object
    post_data = { "defensio-result" =>
                  { "api-version"       => API_VERSION, 
                   "status"            => "success", 
                   "message"           => nil, 
                   "signature"         => "123456",
                   "allow"             => false,
                   "classification"    => "malicious",
                   "spaminess"         => 0.95,
                   "profanity-match"  => true }
                }
    
    fake_request_object = OpenStruct.new(:body => StringIO.new(post_data.to_json))
    result = @d.class.handle_post_document_async_callback(fake_request_object)
    assert_equal Hash, result.class
    assert_equal "success", result["status"]
    
    fake_request_object = OpenStruct.new(:body => StringIO.new(post_data.to_json))
    result = @d.handle_post_document_async_callback(fake_request_object)
    assert_equal Hash, result.class
    assert_equal "success", result["status"]
  end

  def test_handle_post_document_async_callback__invalid_object_type
    assert_raise(ArgumentError) { @d.class.handle_post_document_async_callback(nil) }
    assert_raise(ArgumentError) { @d.handle_post_document_async_callback(nil) }
  end

  
  # OTHER TESTS
  def test_api_path
    assert_equal "/#{API_VERSION}/users/#{@api_key}.json", @d.send(:api_path)
    assert_equal "/#{API_VERSION}/users/#{@api_key}/documents.json", @d.send(:api_path, "documents")
    assert_equal "/#{API_VERSION}/users/#{@api_key}/documents/abcdefghijklmnop.json", @d.send(:api_path, "documents", "abcdefghijklmnop")
  end
  
  def test_parse_body
    parsed = {"hello"=>"world"}
    assert_equal parsed, @d.send(:parse_body, '{"defensio-result":{"hello":"world"}}')
  end

  # HELPERS AND SETUP
  def setup
    if ENV['DEFENSIO_KEY'].nil?
      puts "You must set the DEFENSIO_KEY environment variable before running tests. Example:"
      puts "$ DEFENSIO_KEY=<your api key here> ruby test/defensio_test.rb"
      puts "Fail. Epic Fail."
      exit 1
    end

    @api_key = ENV['DEFENSIO_KEY']
    @d = Defensio.new(@api_key)
  end
end