require 'freshbooks'

def build_xml(data)
  FreshBooks::Connection.build_xml data
end

describe "XML generation:" do
  describe "simple hash" do
    it "should serialize correctly" do
      data = {"foo" => "bar"}
      build_xml(data).should == "<foo>bar</foo>"
    end
  end

  describe "simple hash with Fixnum value" do
    it "should serialize correctly, coercing to string" do
      data = {"foo" => 1}
      build_xml(data).should == "<foo>1</foo>"
    end
  end

  describe "simple hash value containing entity" do
    it "should serialize correctly, escaping entity" do
      data = {"foo" => "b&r"}
      build_xml(data).should == "<foo>b&amp;r</foo>"
    end
  end

  describe "nested hash" do
    it "should serialize correctly" do
      data = {"foo" => {"bar" => "baz"}}
      build_xml(data).should == "<foo><bar>baz</bar></foo>"
    end
  end

  describe "deeply nested hash" do
    it "should serialize correctly" do
      data = {"foo" => {"bar" => {"baz" => "bat"}}}
      build_xml(data).should == "<foo><bar><baz>bat</baz></bar></foo>"
    end
  end

  describe "array" do
    it "should serialize correctly" do
      data = [{"bar" => "baz"}, {"bar" => "baz"}]
      build_xml(data).should == "<bar>baz</bar><bar>baz</bar>"
    end
  end

  describe "hash with array" do
    it "should serialize correctly" do
      data = {"foo" => [{"bar" => "baz"}, {"bar" => "baz"}]}
      build_xml(data).should == "<foo><bar>baz</bar><bar>baz</bar></foo>"
    end
  end
end
