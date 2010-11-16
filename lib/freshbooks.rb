require 'httparty'
require 'builder'
require 'openssl'
require 'cgi'

module FreshBooks
  API_VERSION = '2.1'

  # provides a Hash-like response object with structure
  # isomorphic to actual xml response, slightly tidied.
  class Response < Hash
    attr_reader :status

    def initialize(data)
      super nil
      response = data["response"]
      response.delete "xmlns"
      @status = response.delete "status"
      update response
    end

    def success?
      status == "ok"
    end
  end

  class Connection              # :nodoc:
    # <b>DEPRECATED:</b> Please use <tt>FreshBooks::Client.new</tt> instead.
    def self.new(*args)
      warn "[DEPRECATED] `FreshBooks::Connection` is deprecated.  Please use `FreshBooks::Client` instead."
      Client.new(*args)
    end
  end

  # FreshBooks API client. instances are FreshBooks account
  # specific so you can, e.g. setup two clients and copy/
  # sync data between them
  module Client
    include HTTParty

    # :call-seq:
    #   new(domain, api_token) => FreshBooks::TokenClient
    #   new(domain, consumer_key, consumer_secret, token, token_secret) => FreshBooks::OAuthClient
    #
    # creates a new FreshBooks API client. returns the appropriate client
    # type based on the authorization arguments provided
    def self.new(*args)
      case args.size
      when 2 then TokenClient.new(*args)
      when 5 then OAuthClient.new(*args)
      else raise ArgumentError
      end
    end

    def api_url                 # :nodoc:
      "https://#{@domain}/api/#{API_VERSION}/xml-in"
    end

    # HTTParty (sort of) assumes global connections to services
    # but we can easily avoid that by making an instance method
    # that knows account-specific details that calls its
    # coresponding class method.
    # note: we only need to provide a #post method because the
    # FreshBooks API is POST only
    def post(method, params={}) # :nodoc:
      Response.new Client.post(api_url,
                               :headers => auth,
                               :body => Client.xml_body(method, params))
    end

    # takes nested Hash/Array combos and generates isomorphic
    # XML bodies to be POSTed to FreshBooks API
    def self.xml_body(method, params)
      xml = Builder::XmlMarkup.new(:indent => 2)
      xml.instruct! :xml, :version=>"1.0", :encoding=>"utf-8"
      xml.tag!("request", :method => method) do
        build_xml(params, xml)
      end
      xml.target!
    end

    # helper method to xml_body
    def self.build_xml(obj, xml=Builder::XmlMarkup.new)
      # ZOMG! haven't you ever heard of polymorphism?!?
      # of course. I'm simply electing not to pollute the
      # method space of two of the most common Ruby classes.
      # besides, what are the chances this library will ever
      # be used in a context where some other library hasn't
      # already defined #to_xml on Hash...
      case obj
      when Hash
        obj.each do |k,v|
          if [Hash, Array].include?(v.class)
            xml.tag!(k) { build_xml(v, xml) }
          else
            xml.__send__(k, v)
          end
        end
      when Array then obj.each { |e| build_xml(e, xml) }
      end
      xml.target!
    end

    # infer API methods based on 2-(and sometimes 3) deep method
    # chains sent to clients. this allows us to provide a simple
    # interface without actually knowing anything about the supported
    # API methods (and hence trusting users to read the official
    # FreshBooks API documentation)
    def method_missing(sym, *args) # :nodoc:
      NamespaceProxy.new self, sym
    end

    # nothing to see here...
    class NamespaceProxy < Struct.new(:client, :namespace) # :nodoc:
      def method_missing(sym, *args)
        # check for subordinate resources
        if [:invoice, :recurring].include?(namespace) and
            sym == :lines
          NamespaceProxy.new client, "#{namespace}.#{sym}"
        else
          client.post "#{namespace}.#{sym}", *args
        end
      end
    end

    class FreshBooksAPIRequest < HTTParty::Request
      private
      # HACK
      # FreshBooks' API unfortunately redirects to a login search
      # html page if you specify an endpoint that doesn't exist
      # (i.e. typo in subdomain) instead of returning a 404
      def handle_response
        if loc = last_response['location'] and loc.match /loginSearch\.php$/
          resp = Net::HTTPNotFound.new(1.1, 404, "Not Found")
          resp.instance_variable_set :@read, true
          resp.instance_variable_set :@body, <<EOS
<?xml version="1.0" encoding="utf-8"?>
<response xmlns="http://www.freshbooks.com/api/" status="fail">
  <error>Not Found. Verify FreshBooks API endpoint</error>
</response>
EOS
          self.last_response = resp
        end
        super
      end
    end

    def self.post(path, options={}) # :nodoc:
      perform_freshbooks_api_request Net::HTTP::Post, path, options
    end

    private
    def self.perform_freshbooks_api_request(http_method, path, options) #:nodoc:
      options = default_options.dup.merge(options)
      process_cookies(options)
      FreshBooksAPIRequest.new(http_method, path, options).perform
    end
  end

  # Basic Auth client. uses an account's API token.
  class TokenClient
    include Client

    def initialize(domain, api_token)
      @domain = domain
      @username = api_token
      @password = 'X'
    end

    def auth
      { 'Authorization' =>
        # taken from lib/net/http.rb
        'Basic ' + ["#{@username}:#{@password}"].pack('m').delete("\r\n") }
    end
  end

  # OAuth 1.0 client. access token and secret must be obtained elsewhere.
  # cf. the {oauth gem}[http://oauth.rubyforge.org/]
  class OAuthClient
    include Client

    def initialize(domain, consumer_key, consumer_secret, token, token_secret)
      @domain          = domain
      @consumer_key    = consumer_key
      @consumer_secret = consumer_secret
      @token           = token
      @token_secret    = token_secret
    end

    def auth
      data = {
        :realm                  => '',
        :oauth_version          => '1.0',
        :oauth_consumer_key     => @consumer_key,
        :oauth_token            => @token,
        :oauth_timestamp        => timestamp,
        :oauth_nonce            => nonce,
        :oauth_signature_method => 'PLAINTEXT',
        :oauth_signature        => signature,
      }.map { |k,v| %Q[#{k}="#{v}"] }.join(',')

      { 'Authorization' => "OAuth #{data}" }
    end

    def signature
      CGI.escape("#{@consumer_secret}&#{@token_secret}")
    end

    def nonce
      [OpenSSL::Random.random_bytes(10)].pack('m').gsub(/\W/, '')
    end

    def timestamp
      Time.now.to_i
    end
  end
end
