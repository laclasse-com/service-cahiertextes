require_relative 'test_helper'

class TestLaclasseFunctions
  def testing
    1
  end
end

describe TestLaclasseFunctions do 

  before(:all) do
    @lclassefunc = TestLaclasseFunctions.new
  end
  
  it "Should be good to test something..." do 
    @lclassefunc.testing.should be 1
  end
  
end