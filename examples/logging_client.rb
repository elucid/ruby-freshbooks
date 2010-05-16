require 'rubygems'
require 'ruby-freshbooks'
require 'logger'

module FreshBooks
  class LoggingClient < TokenClient
    def initialize(domain, api_token, logger)
      @logger = logger
      super domain, api_token
    end

    def post(method, params={})
      body = Client.xml_body(method, params)
      @logger.info "\n== Request ==\n#{body}"
      data = Client.post(api_url,
                         :headers => auth,
                         :body => body)
      @logger.info "\n== Response ==\n#{data.body}\n"
      Response.new data
    end
  end
end

logger = Logger.new(STDOUT)

lc = FreshBooks::LoggingClient.new('youraccount.freshbooks.com',
                                   'yourfreshbooksapitoken',
                                   logger)

lc.client.get :client_id => 2
# prints the following to standard out:
#
# I, [2010-05-15T22:42:23.496144 #91945]  INFO -- :
# == Request ==
# <?xml version="1.0" encoding="utf-8"?>
# <request method="client.get">
#   <client_id>2</client_id>
# </request>
#
#
# I, [2010-05-15T22:42:24.061579 #91945]  INFO -- :
# == Response ==
# <?xml version="1.0" encoding="utf-8"?>
# <response xmlns="http://www.freshbooks.com/api/" status="ok">
#   <client>
#     <client_id>2</client_id>
#     <username>foolhardy</username>
#     ...
#   </client>
# </repsonse>
