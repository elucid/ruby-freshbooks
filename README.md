# ruby-freshbooks: a simple FreshBooks API wrapper

This is a Ruby wrapper for the [FreshBooks](http://www.freshbooks.com) API. This style of API wrapper is typically called "reflective". However, because most web APIs (and in particular, FreshBooks' API) do not provide enough metadata to actually be reflective, I feel a more appropriate term is "isomorphic". i.e. the wrapper translates native (in this case Ruby) data structures to and from some representation (in this case XML) that the API understands.

For example,

    c = FreshBooks::Client.new('youraccount.freshbooks.com', 'yourfreshbooksapitoken')
    c.client.get :client_id => 2

generates the XML:

    <?xml version="1.0" encoding="utf-8"?>
    <request method="client.get">
      <client_id>2</client_id>
    </request>

purely based on the request arguments. This library doesn't actually know anything about the FreshBooks API. Instead it relies on users to read the [FreshBooks API Documentation](http://developers.freshbooks.com/api) and build Ruby data structures (i.e. nested Hash and Array combos) that have isomorphic structure to intended API XML requests. The transformation is quite simple; once you understand how the mapping works any FreshBooks API request can easily be written as a Ruby data structure.

## Detailed Ruby Data Structure to XML Isomorphism Example

The following call will generate and POST the invoice create XML shown in the [FreshBooks API Documentation](http://developers.freshbooks.com/api/view/invoices/):

    c = FreshBooks::Client.new('youraccount.freshbooks.com', 'yourfreshbooksapitoken')
    c.invoice.create(:invoice => {
                          :client_id     => 13,
                          :number        => 'FB00004',
                          :status        => 'draft',
                          :date          => '2007-06-23',
                          :po_number     => 2314,
                          :discount      => 10,
                          :notes         => 'Due upon receipt.',
                          :currency_code => 'CAD',
                          :terms         => 'Payment due in 30 days.',
                          :return_uri    => 'http://example.com/account',
    
                          :first_name    => 'John',
                          :last_name     => 'Smith',
                          :organization  => 'ABC Corp',
                          :p_street1     => nil,
                          :p_street2     => nil,
                          :p_city        => nil,
                          :p_state       => nil,
                          :p_country     => nil,
                          :p_code        => nil,
                          :vat_name      => nil,
                          :vat_number    => nil,
    
                          :lines => [{ :line => {
                                         :name         => 'Yard Work',
                                         :description  => 'Mowed the lawn.',
                                         :unit_cost    => 10,
                                         :quantity     => 4,
                                         :tax1_name    => 'GST',
                                         :tax2_name    => 'PST',
                                         :tax1_percent => 5,
                                         :tax2_percent => 8,
                                       }}]})


## Examples

You can call any `#{namespace}.#{method_name}` method chain against a `FreshBooks::Client` instance and it will POST a request with the corresponding FreshBooks API method. i.e.

    c = FreshBooks::Client.new('youraccount.freshbooks.com', 'yourfreshbooksapitoken')
    c.client.get   :client_id => 37
    c.invoice.list :client_id => 37, :page => 2, :per_page => 10

## Authentication

You can authenticate using either API tokens or [OAuth](http://oauth.net/). The `FreshBooks::Client.new` constructor will create a client instance of the appropriate type depending on the arguments you pass in. so

    c = FreshBooks::Client.new('youraccount.freshbooks.com', 'yourfreshbooksapitoken')

will return a `FreshBooks::TokenClient` instance, and

    c = FreshBooks::Client.new('youraccount.freshbooks.com', 'your_consumer_key', 'your_consumer_secret', 'your_access_token', 'your_access_token_secret')

will return a `FreshBooks::OAuthClient` instance. both client classes work identically aside from how they authenticate requests.

*note:* this library provides no suppport for obtaining OAuth request or access tokens. for help with that take a look at [FreshBooks' OAuth Documentation](http://developers.freshbooks.com/api/oauth/) and the [oauth gem](http://oauth.rubyforge.org/).

## Goals

* easy to use. you can get started using this wrapper in 5 minutes without having to read any documentation
* flexible enough to support minor changes to the FreshBooks API without requiring a new release. users can simply refer to the official [FreshBooks API Documentation](http://developers.freshbooks.com/api) to see what they can and can't do. you need not depend on this library's maintainer to map/remove new attributes, methods or namespaces as the FreshBooks API changes

## Non-goals

* seamless integration with FreshBooks API via an object interface. i.e.

<pre><code>invoices = FreshBooks::Invoice.list
invoice = invoices.first
invoice.amount = 500.00
invoice.update
</code></pre>

if you want this sort of thing, please use [freshbooks.rb](http://github.com/bcurren/freshbooks.rb) instead

## Why Shouldn't I use freshbooks.rb Instead?

Maybe you should. It depends on what you want to do. I've used freshbooks.rb before but there were a few things that didn't work for me:

* global connection. I've had the need to connect to multiple FreshBooks accounts within the same program to do things like sync or migrate data. you can't do this with freshbooks.rb because the global connection is owned by `FreshBooks::Base` which is the superclass of `Item`, `Invoice`, etc.
* requiring a library update every time the FreshBooks API changes. although this doesn't happen very often, it's a little annoying to have to manually patch freshbooks.rb when it does.
* having to convert everything to and from the business objects the library provides. because the freshbooks.rb API is nice and abstract, it's easy to play around with invoices, clients, etc. as business objects. however, this is less convenient for mass import/export type programs because your data has to be pushed through that object interface instead of just transformed into YAML, CSV, etc. it's also less than desirable when your integration makes use of an alternate model class (i.e. an `ActiveRecord` subclass that you're using to save your FreshBooks data into a database).
* data transparency. if you're just exploring the FreshBooks API, you might not know all of the attributes that some data types exposes. if you are getting back nicely packaged objects, you'll need to read through the documentation (or source code of freshbooks.rb if you're sure some property ought to be there but isn't and you suspect it's missing from the mapping) to see what you have access to.

## Installation

    gem install ruby-freshbooks


## Links

* [FreshBooks API Documentation](http://developers.freshbooks.com/api)
* [Source Code](http://github.com/elucid/ruby-freshbooks)
* [RapidAPI](https://rapidapi.com/package/FreshbooksAPI/functions?utm_source=FreshbooksGitHub&utm_medium=button)

## If You Want to Contribute:

1. fork http://github.com/elucid/ruby-freshbooks
2. make your changes along with specs (don't touch VERSION)
3. send me a pull request

## TODO

* more examples
* more documentation

## Copyright

Copyright (c) 2010 Justin Giancola. See LICENSE for details.
