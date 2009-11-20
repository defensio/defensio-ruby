require File.dirname(__FILE__) + "/../lib/defensio"
DEFENSIO_ENV = "test"
require 'test/unit'
require 'mocha'
require 'redgreen'
require 'ostruct'

class DefensioTest < Test::Unit::TestCase
  MOCK_RESPONSE = true
  API_KEY       = "1234567890"
  OWNER_URL     = "http://example.org"
  SIGNATURE     = "abcdefghijklmnop"

  LIB_VERSION = 0.1
  API_VERSION = 2.0
  API_HOST    = "http://api.defensio.com"
  FORMAT      = :yaml
  HEADERS     = {"User-Agent" => "Defensio-Ruby 0.1", "Content-Type" => "text/yaml"}

  # API METHOD TESTS -- Useful to learn how to use the library
  def test_get_user
    if MOCK_RESPONSE
      Patron::Session.any_instance.expects(:get).with("#{API_HOST}/#{API_VERSION}/users/#{API_KEY}.#{FORMAT}").once.returns(FakePatronResponse.new(200, user_body))
    end
    
    status, body = @d.get_user
    assert body.is_a?(Hash)
    assert_equal 200, status
    assert_equal "success", body["status"]
  end

  def test_post_document
    if MOCK_RESPONSE
      query = "client=Defensio-Ruby%20%7C%200.1%20%7C%20Carl%20Mercier%20%7C%20cmercier@websense.com&content=We%20sell%20cheap%20Viagra!%20[spam,0.95]&platform=my_awesome_app&type=test"
      Patron::Session.any_instance.expects(:post).with("#{API_HOST}/#{API_VERSION}/users/#{API_KEY}/documents.#{FORMAT}?#{query}", {}).once.returns(FakePatronResponse.new(200, document_body(SIGNATURE)))
    end

    data = { :content => "We sell cheap Viagra! [spam,0.95]", :platform => "my_awesome_app", :type => "test" }
    status, body = @d.post_document(data)
    assert body.is_a?(Hash)
    assert_equal 200, status
    assert_equal "success", body["status"]
    assert body["signature"].is_a?(String)
  end
  
  def test_get_document
    if MOCK_RESPONSE
      Patron::Session.any_instance.expects(:get).with("#{API_HOST}/#{API_VERSION}/users/#{API_KEY}/documents/#{SIGNATURE}.#{FORMAT}").once.returns(FakePatronResponse.new(200, document_body(SIGNATURE)))
    end
    
    status, body = @d.get_document(SIGNATURE)
    assert body.is_a?(Hash)
    assert_equal 200, status
    assert_equal "success", body["status"]
    assert_equal SIGNATURE, body["signature"]
  end

  def test_put_document
    if MOCK_RESPONSE
      query = "allow=true"
      Patron::Session.any_instance.expects(:put).with("#{API_HOST}/#{API_VERSION}/users/#{API_KEY}/documents/#{SIGNATURE}.#{FORMAT}?#{query}", {}).once.returns(FakePatronResponse.new(200, document_body_allowed(SIGNATURE)))
    end

    status, body = @d.put_document(SIGNATURE, :allow => true)
    assert body.is_a?(Hash)
    assert_equal 200, status
    assert_equal "success", body["status"]
    assert_equal SIGNATURE, body["signature"]
    assert_equal true, body["allow"]
  end
  
  def test_get_basic_stats
    if MOCK_RESPONSE
      Patron::Session.any_instance.expects(:get).with("#{API_HOST}/#{API_VERSION}/users/#{API_KEY}/basic-stats.#{FORMAT}").once.returns(FakePatronResponse.new(200, basic_stats_body))
    end
    
    status, body = @d.get_basic_stats
    assert body.is_a?(Hash)
    assert_equal 200, status
    assert_equal "success", body["status"]
    assert body["unwanted"]["total"].is_a?(Integer)
  end

  def test_get_extended_stats
    if MOCK_RESPONSE
      query="from=2009-09-01&to=2009-09-03"
      Patron::Session.any_instance.expects(:get).with("#{API_HOST}/#{API_VERSION}/users/#{API_KEY}/extended-stats.#{FORMAT}?#{query}").once.returns(FakePatronResponse.new(200, extended_stats_body))
    end
    
    status, body = @d.get_extended_stats(:from => Date.new(2009, 9, 1), :to => Date.new(2009, 9, 3))
    assert body.is_a?(Hash)
    assert_equal 200, status
    assert_equal "success", body["status"]
    assert body["data"].is_a?(Array)
    assert body["data"][0]["date"].is_a?(Date)
  end
  
  def test_post_dictionary_filter
    if MOCK_RESPONSE
      query="OtherField=hello%20again&field1=hello%20world"
      Patron::Session.any_instance.expects(:post).with("#{API_HOST}/#{API_VERSION}/users/#{API_KEY}/dictionary-filter.#{FORMAT}?#{query}", {}).once.returns(FakePatronResponse.new(200, dictionary_filter_body))
    end
    
    status, body = @d.post_dictionary_filter("field1"=>"hello world", "OtherField"=>"hello again")
    assert body.is_a?(Hash)
    assert_equal 200, status
    assert_equal "success", body["status"]
    assert body["filtered"].is_a?(Array)
    assert_equal "field1", body["filtered"][0]["key"]
    assert_equal "OtherField", body["filtered"][1]["key"]
  end
  
  def test_handle_post_document_async_callback__string
    result = { "api-version"       => API_VERSION, 
               "status"            => "success", 
               "message"           => nil, 
               "signature"         => SIGNATURE,
               "allow"             => false,
               "classification"    => "malicious",
               "spaminess"         => 0.95,
               "dictionary-match"  => true }

    assert_equal result, @d.class.handle_post_document_async_callback(document_body(SIGNATURE))
    assert_equal result, @d.handle_post_document_async_callback(document_body(SIGNATURE))
  end

  def test_handle_post_document_async_callback__request_object
    result = { "api-version"       => API_VERSION, 
               "status"            => "success", 
               "message"           => nil, 
               "signature"         => SIGNATURE,
               "allow"             => false,
               "classification"    => "malicious",
               "spaminess"         => 0.95,
               "dictionary-match"  => true }
    
    fake_request_object = OpenStruct.new(:body => StringIO.new(document_body(SIGNATURE)))
    assert_equal result, @d.class.handle_post_document_async_callback(fake_request_object)

    fake_request_object = OpenStruct.new(:body => StringIO.new(document_body(SIGNATURE)))
    assert_equal result, @d.handle_post_document_async_callback(fake_request_object)
  end

  def test_handle_post_document_async_callback__invalid_object_type
    assert_raise(ArgumentError) { @d.class.handle_post_document_async_callback(nil) }
    assert_raise(ArgumentError) { @d.handle_post_document_async_callback(nil) }
  end

  
  # OTHER TESTS
  def test_http_session
    s = @d.send(:http_session)
    assert s.is_a?(Patron::Session)
    if @d.class.class_eval("KEEP_ALIVE")
      assert_equal s, @d.send(:http_session) # make sure sessions are reused when KEEP_ALIVE is true
    else
      assert_not_equal s, @d.send(:http_session) # make sure sessions are dropped when KEEP_ALIVE is false
    end
    
    assert_equal HEADERS, s.headers
  end

  def test_api_url
    assert_equal "#{API_HOST}/#{API_VERSION}/users/#{API_KEY}.yaml", @d.send(:api_url)
    assert_equal "#{API_HOST}/#{API_VERSION}/users/#{API_KEY}/documents.yaml", @d.send(:api_url, "documents")
    assert_equal "#{API_HOST}/#{API_VERSION}/users/#{API_KEY}/documents/abcdefghijklmnop.yaml", @d.send(:api_url, "documents", "abcdefghijklmnop")
  end
  
  def test_hash_to_query_string
    assert_equal "hello-world=true", @d.send(:hash_to_query_string, {:hello_world => true} )
    assert_equal "hello-world=this%20has%20spaces%20and%20characters%20($%20?%20&%20%5E%20%C3%A9)%20that%20should%20be%20escaped", 
      @d.send(:hash_to_query_string, {:hello_world => "this has spaces and characters ($ ? & ^ é) that should be escaped"} )
    assert_equal "value1=true&value2=true&value3=true", @d.send(:hash_to_query_string, { "value1" => true, "value2" => true, :value3 => true})
    assert_equal "date=2009-01-01", @d.send(:hash_to_query_string, { "date" => Date.new(2009,1,1) })
    assert_nil @d.send(:hash_to_query_string, nil)
  end
  
  def test_parse_body
    parsed = {"hello"=>"world"}
    assert_equal parsed, @d.send(:parse_body, "---\ndefensio-result:\n  hello: world")
  end

  # HELPERS AND SETUP
  def setup
    @d = Defensio.new(API_KEY)
  end

  def http_session
    @d.send(:http_session)
  end
  
  def base_url
    "#{API_HOST}/#{API_VERSION}"
  end

  # MOCKING
  class FakePatronResponse < Struct.new(:status, :body); end
  
  def user_body
    { "defensio-result" => {"api-version" => API_VERSION, "status" => "success", "message" => nil, "owner-url" => OWNER_URL} }.send("to_#{FORMAT}")
  end
  
  def document_body(signature)
    { "defensio-result" => {
        "api-version"       => API_VERSION, 
        "status"            => "success", 
        "message"           => nil, 
        "signature"         => signature, 
        "allow"             => false,
        "classification"    => "malicious",
        "spaminess"         => 0.95,
        "dictionary-match"  => true } 
    }.send("to_#{FORMAT}")
  end

  def document_body_allowed(signature)
    { "defensio-result" => {
        "api-version"       => API_VERSION, 
        "status"            => "success", 
        "message"           => nil, 
        "signature"         => signature, 
        "allow"             => true,
        "classification"    => "innocent",
        "spaminess"         => 0.95,
        "dictionary-match"  => true } 
    }.send("to_#{FORMAT}")
  end
  
  def basic_stats_body
    { "defensio-result" => {
      "api-version"       => API_VERSION, 
      "status"            => "success", 
      "message"           => nil, 
      "recent-accuracy"   => 0.9975,
      "legitimate"        => { "total" => 100 },
      "unwanted"          => { "total" => 100, "malicious" => 50, "spam" => 100},
      "false-positives"   => 1,
      "false-negatices"   => 2,
      "learning"          => true,
      "learning-status"   => "Details about learning mode" }
    }.send("to_#{FORMAT}")
  end
  
  def extended_stats_body
    { "defensio-result" => {
      "api-version"       => API_VERSION, 
      "status"            => "success", 
      "message"           => nil,
      "data" => [ 
        { "date"            => "2009-09-01",
          "recent-accuracy" => 0.9975,
          "legitimate"      => 100,
          "unwanted"        => 500,
          "false-positives" => 1,
          "false-negatives" => 0 }, 
        {
          "date"            => "2009-09-02",
          "recent-accuracy" => 0.9985,
          "legitimate"      => 50,
          "unwanted"        => 475,
          "false-positives" => 0,
          "false-negatives" => 0 }, 
        { "date"            => "2009-09-03",
          "recent-accuracy" => 0.9992,
          "legitimate"      => 100,
          "unwanted"        => 500,
          "false-positives" => 1,
          "false-negatives" => 0 } 
      ],
      "chart-urls" => {
        "recent-accuracy" => "http://domain.com/chart/123456",
        "total-unwanted"  => "http://domain.com/chart/abcdef",
        "total-legitimate" => "http://domain.com/chart/xyzabc" }
      } 
    }.send("to_#{FORMAT}")
  end
  
  def dictionary_filter_body
    { "defensio-result" => {
      "api-version"       => API_VERSION, 
      "status"            => "success", 
      "message"           => nil,
      "filtered" => [ 
        { "key"   => "field1",     "value" => "hello world" },
        { "key"   => "OtherField", "value" => "hello again" }
      ] }
    }.send("to_#{FORMAT}")
  end
end