require 'httparty'
require 'builder'

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
  class Client
    include HTTParty

    def initialize(domain, token)
      @domain = domain
      @auth = { :username => token, :password => 'X' }
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
      Response.new self.class.post(api_url,
                                   :basic_auth => @auth,
                                   :body => self.class.xml_body(method, params))
    end

    # takes nested Hash/Array combos and generates isomorphic
    # XML bodies to be POSTed to FreshBooks API
    def self.xml_body(method, params)
      xml = Builder::XmlMarkup.new
      xml.tag!("request", :method => method) do
        build_xml(params, xml)
      end
      xml.target!
    end

    # helper method to xml_body
    def self.build_xml(obj, target='')
      xml = Builder::XmlMarkup.new(:target => target)
      # ZOMG! haven't you ever heard of polymorphism?!?
      # of course. I'm simply electing not to pollute the
      # method space of two of the most common Ruby classes.
      # besides, what are the chances this library will ever
      # be used in a context where some other library hasn't
      # already defined #to_xml on Hash...
      case obj
      when Hash  then obj.each { |k,v| xml.tag!(k) { build_xml(v, xml) } }
      when Array then obj.each { |e| build_xml(e ,xml) }
      else xml.text! obj.to_s
      end
      xml.target!
    end

    # infer API methods based on 2-deep method chains sent to
    # clients. this allows us to provide a simple interface
    # without actually knowing anything about the supported API
    # methods (and hence trusting users to read the official
    # FreshBooks API documentation)
    def method_missing(sym, *args) # :nodoc:
      NamespaceProxy.new self, sym
    end

    # nothing to see here...
    class NamespaceProxy < Struct.new(:client, :namespace) # :nodoc:
      def method_missing(sym, *args)
        client.post "#{namespace}.#{sym}", *args
      end
    end
  end
end
