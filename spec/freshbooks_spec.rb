require 'lib/ruby-freshbooks'

def build_xml(data)
  FreshBooks::Client.build_xml data, Builder::XmlMarkup.new(:indent => 2)
end

describe "XML generation:" do
  describe "simple hash" do
    it "should serialize correctly" do
      data = {"foo" => "bar"}
      build_xml(data).should == "<foo>bar</foo>\n"
    end
  end

  describe "simple hash with Fixnum value" do
    it "should serialize correctly, coercing to string" do
      data = {"foo" => 1}
      build_xml(data).should == "<foo>1</foo>\n"
    end
  end

  describe "simple hash value containing entity" do
    it "should serialize correctly, escaping entity" do
      data = {"foo" => "b&r"}
      build_xml(data).should == "<foo>b&amp;r</foo>\n"
    end
  end

  describe "nested hash" do
    it "should serialize correctly" do
      data = {"foo" => {"bar" => "baz"}}
      build_xml(data).should == "<foo>\n  <bar>baz</bar>\n</foo>\n"
    end
  end

  describe "deeply nested hash" do
    it "should serialize correctly" do
      data = {"foo" => {"bar" => {"baz" => "bat"}}}
      build_xml(data).should == "<foo>\n  <bar>\n    <baz>bat</baz>\n  </bar>\n</foo>\n"
    end
  end

  describe "array" do
    it "should serialize correctly" do
      data = [{"bar" => "baz"}, {"bar" => "baz"}]
      build_xml(data).should == "<bar>baz</bar>\n<bar>baz</bar>\n"
    end
  end

  describe "hash with array" do
    it "should serialize correctly" do
      data = {"foo" => [{"bar" => "baz"}, {"bar" => "baz"}]}
      build_xml(data).should == "<foo>\n  <bar>baz</bar>\n  <bar>baz</bar>\n</foo>\n"
    end
  end
end

describe "FreshBooks Client" do
 describe "instantiation" do
    it "should create a TokenClient instance when Connection.new is called" do
      c = FreshBooks::Connection.new('foo.freshbooks.com', 'abcdefghijklm')
      c.should be_a(FreshBooks::TokenClient)
    end
  end

  describe "proxies" do
    before(:each) do
      @c = FreshBooks::Connection.new('foo.freshbooks.com', 'abcdefghijklm')
    end

    it "should not hit API for single method send" do
      @c.should_not_receive(:post)
      @c.invoice
    end

    it "should hit API for normal double method send" do
      @c.should_receive(:post, "invoice.list").once
      @c.invoice.list
    end

    it "should not hit API for subordinate resource double method send" do
      @c.should_not_receive(:post)
      @c.invoice.lines
    end

    it "should hit API for subordinate resource triple method send" do
      @c.should_receive(:post, "invoice.items.add").once
      @c.invoice.lines.add
    end
  end
end
