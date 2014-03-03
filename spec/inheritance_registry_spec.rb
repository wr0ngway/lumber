require 'spec_helper'

describe Lumber::InheritanceRegistry do

  before(:each) do
    InheritanceRegistry.clear
  end

  it "allows registering a class" do
    InheritanceRegistry['Foo'] = 'root::Foo'
    InheritanceRegistry['Foo'].should == 'root::Foo'
  end

  it "allows clearing registry" do
    InheritanceRegistry['Foo'] = 'root::Foo'
    InheritanceRegistry['Foo'].should == 'root::Foo'
    InheritanceRegistry.clear
    InheritanceRegistry['Foo'].should be_nil
  end

  describe "#find_registered_logger" do

    it "returns nil if clazz is nil" do
      InheritanceRegistry.find_registered_logger(nil).should be_nil
    end

    it "returns the registered name if clazz is registered" do
      class Foo; end
      InheritanceRegistry['Foo'] = 'root::Foo'
      InheritanceRegistry.find_registered_logger(Foo).should == "root::Foo"
    end

    it "returns the registered name if superclass is registered" do
      class Foo; end
      class Bar < Foo; end
      InheritanceRegistry['Foo'] = 'root::Foo'
      InheritanceRegistry.find_registered_logger(Bar).should == "root::Foo"
    end

    it "returns the registered name if superclass is registered" do
      class Foo1; end
      class Foo2 < Foo1; end
      class Foo3 < Foo2; end
      class Bar < Foo3; end
      InheritanceRegistry['Foo1'] = 'root::Foo1'
      InheritanceRegistry.find_registered_logger(Bar).should == "root::Foo1"
    end

    it "doesn't use classes past first registered superclass" do
      class Foo1; end
      class Foo2 < Foo1; end
      class Foo3 < Foo2; end
      class Bar < Foo3; end
      InheritanceRegistry['Foo1'] = 'root::Foo1'
      InheritanceRegistry['Foo2'] = 'root::Foo2'
      InheritanceRegistry.find_registered_logger(Bar).should == "root::Foo2"
    end

  end

  describe "#remove_inheritance_handler" do

    it "should remove the handler" do
      defined?(Object.inherited_with_lumber_registry).should be_false
      InheritanceRegistry.register_inheritance_handler
      defined?(Object.inherited_with_lumber_registry).should be_true
      InheritanceRegistry.remove_inheritance_handler
      defined?(Object.inherited_with_lumber_registry).should be_false
    end

  end

  describe "#register_inheritance_handler" do

    before(:each) do
      InheritanceRegistry.remove_inheritance_handler
    end

    it "adds an inheritance handler" do
      defined?(Object.inherited_with_lumber_registry).should be_false
      InheritanceRegistry.register_inheritance_handler
      defined?(Object.inherited_with_lumber_registry).should be_true
    end

    it "doesn't add an inheritance handler multiple times" do
      Object.singleton_class.should_receive(:alias_method_chain).once.and_call_original
      defined?(Object.inherited_with_lumber_registry).should be_false
      InheritanceRegistry.register_inheritance_handler
      defined?(Object.inherited_with_lumber_registry).should be_true
      InheritanceRegistry.register_inheritance_handler
      defined?(Object.inherited_with_lumber_registry).should be_true
    end

    it "doesn't change classes that aren't registered" do
      InheritanceRegistry.register_inheritance_handler
      class Foo; end
      Foo.ancestors.should_not include(Lumber::LoggerSupport)
    end

    it "adds logger support for classes that are registered" do
      InheritanceRegistry.register_inheritance_handler
      InheritanceRegistry["Foo"] = "root::Foo"
      class Foo; end
      Foo.ancestors.should include(Lumber::LoggerSupport)
    end

  end

end
