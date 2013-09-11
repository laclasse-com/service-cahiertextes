# TODO: finish mocking and stubbing specs

describe "Array#cmp", ->
  it "calls <=> left to right and return first non-0 result", ->
    # [-1, +1, nil, "foobar"].each do |result|
    #   lhs = Array.new(3) { mock("#{result}") }
    #   rhs = Array.new(3) { mock("#{result}") }

    #   lhs[0].should_receive(:<=>).with(rhs[0]).and_return(0)
    #   lhs[1].should_receive(:<=>).with(rhs[1]).and_return(result)
    #   lhs[2].should_not_receive(:<=>)

    #   (lhs <=> rhs).should == result

  it "returns 0 if the arrays are equal", ->
    expect( R([]).cmp []).toEqual  0
    expect( R([1, 2, 3, 4, 5, 6]).cmp [1, 2, 3, 4, 5.0, 6.0]).toEqual  0

  it "returns -1 if the array is shorter than the other array", ->
    expect( R([]).cmp [1]).toEqual -1
    expect( R([1, 1]).cmp [1, 1, 1]).toEqual -1

  it "returns +1 if the array is longer than the other array", ->
    expect( R([1]).cmp []).toEqual +1
    expect( R([1, 1, 1]).cmp [1, 1]).toEqual +1

  it "returns -1 if the other array has a higher number", ->
    expect( R([1]).cmp [2]).toEqual -1
    expect( R([1, 1, 1]).cmp [1, 1, 2]).toEqual -1

  it "returns +1 if the other array has a lower number", ->
    expect( R([1]).cmp [0]).toEqual +1
    expect( R([1, 1, 1]).cmp [1, 1, 0]).toEqual +1

  # it "returns -1 if the arrays have same length and a pair of corresponding elements returns -1 for <=>", ->
  #   eq_l = mock('an object equal to the other')
  #   eq_r = mock('an object equal to the other')
  #   eq_l.should_receive(:<=>).with(eq_r).any_number_of_times.and_return(0)

  #   less = mock('less than the other')
  #   greater = mock('greater then the other')
  #   less.should_receive(:<=>).with(greater).any_number_of_times.and_return(-1)

  #   rest = mock('an rest element of the arrays')
  #   rest.should_receive(:<=>).with(rest).any_number_of_times.and_return(0)
  #   lhs = [eq_l, eq_l, less, rest]
  #   rhs = [eq_r, eq_r, greater, rest]

  #   (lhs <=> rhs).should == -1

  # it "returns +1 if the arrays have same length and a pair of corresponding elements returns +1 for <=>", ->
  #   eq_l = mock('an object equal to the other')
  #   eq_r = mock('an object equal to the other')
  #   eq_l.should_receive(:<=>).with(eq_r).any_number_of_times.and_return(0)

  #   greater = mock('greater then the other')
  #   less = mock('less than the other')
  #   greater.should_receive(:<=>).with(less).any_number_of_times.and_return(+1)

  #   rest = mock('an rest element of the arrays')
  #   rest.should_receive(:<=>).with(rest).any_number_of_times.and_return(0)
  #   lhs = [eq_l, eq_l, greater, rest]
  #   rhs = [eq_r, eq_r, less, rest]

  #   (lhs <=> rhs).should == +1

  # ruby_bug "#", "1.8.6.277", ->
  xit "properly handles recursive arrays", ->
    # empty = ArraySpecs.empty_recursive_array
    # (empty <=> empty).should == 0
    # (empty <=> []).should == 1
    # ([] <=> empty).should == -1

    # (ArraySpecs.recursive_array <=> []).should == 1
    # ([] <=> ArraySpecs.recursive_array).should == -1

    # (ArraySpecs.recursive_array <=> ArraySpecs.empty_recursive_array).should == nil

    # array = ArraySpecs.recursive_array
    # (array <=> array).should == 0

  it "tries to convert the passed argument to an Array using #valueOf", ->
    obj =
      valueOf: -> [1, 2, 3]
    expect( R([4, 5]).cmp obj).toEqual (R([4, 5]).cmp obj.valueOf())

  # it "does not call #to_ary on Array subclasses", ->
  #   obj = ArraySpecs.ToAryArray[5, 6, 7]
  #   obj.should_not_receive(:to_ary)
  #   ([5, 6, 7] <=> obj).should == 0

  # ruby_bug "redmine:2276", "1.9.1", ->
  it "returns nil when the argument is not array-like", ->
    expect(R([]).cmp false).toEqual null
