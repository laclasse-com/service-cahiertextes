describe "String#ljust with length, padding", ->
  it "returns a new string of specified length with self left justified and padded with padstr", ->
    expect(R("hello").ljust(20, '1234').valueOf()).toEqual("hello123412341234123")

    expect(R("").ljust(1, "abcd").valueOf()).toEqual("a")
    expect(R("").ljust(2, "abcd").valueOf()).toEqual("ab")
    expect(R("").ljust(3, "abcd").valueOf()).toEqual("abc")
    expect(R("").ljust(4, "abcd").valueOf()).toEqual("abcd")
    expect(R("").ljust(6, "abcd").valueOf()).toEqual("abcdab")

    expect(R("OK").ljust(3, "abcd").valueOf()).toEqual("OKa")
    expect(R("OK").ljust(4, "abcd").valueOf()).toEqual("OKab")
    expect(R("OK").ljust(6, "abcd").valueOf()).toEqual("OKabcd")
    expect(R("OK").ljust(8, "abcd").valueOf()).toEqual("OKabcdab")

  it "pads with whitespace if no padstr is given", ->
    expect(R("hello").ljust(20).valueOf()).toEqual("hello               ")

  it "returns self if it's longer than or as long as the specified length", ->
    expect(R("").ljust(0).valueOf()).toEqual("")
    expect(R("").ljust(-1).valueOf()).toEqual("")
    expect(R("hello").ljust(4).valueOf()).toEqual("hello")
    expect(R("hello").ljust(-1).valueOf()).toEqual("hello")
    expect(R("this").ljust(3).valueOf()).toEqual("this")
    expect(R("radiology").ljust(8, 'minus').valueOf()).toEqual("radiology")

  it "tries to convert length to an integer using to_int", ->
    expect(R("^").ljust(3.8, "_^").valueOf()).toEqual("^_^")
    expect(R("o").ljust(3, "_o").valueOf()).toEqual("o_o")

  it "raises a TypeError when padstr can't be converted", ->
    expect(-> R("hello").ljust(20, [])).toThrow("TypeError")
    expect(-> R("hello").ljust(20, new Object)).toThrow("TypeError")


  it "raises a TypeError when length can't be converted to an integer", ->
    expect( -> R("hello").ljust("x")       ).toThrow("TypeError")
    expect( -> R("hello").ljust("x", "y")  ).toThrow("TypeError")
    expect( -> R("hello").ljust([])        ).toThrow("TypeError")

  it "tries to convert padstr to a string using to_str", ->
    padstr =
      to_str: -> R("123")

    expect( R("hello").ljust(10, padstr) ).toEqual  R("hello12312")

#  it "taints result when self or padstr is tainted", ->
#    expect("x".taint.ljust(4).tainted?.valueOf()).toEqual(true)
#    expect("x".taint.ljust(0).tainted?).toEqual(true)
#    expect("".taint.ljust(0).tainted?).toEqual(true)
#    expect("x".taint.ljust(4, "*").tainted?).toEqual(true)
#    expect("x".ljust(4, "*".taint).tainted?).toEqual(true)
#

   it "raises an ArgumentError when padstr is empty", ->
     expect( -> R("hello").ljust(10, '') ).toThrow("ArgumentError")

#
#  it "returns subclass instances when called on subclasses" do
#    StringSpecs::MyString.new("").ljust(10).should be_kind_of(StringSpecs::MyString)
#    StringSpecs::MyString.new("foo").ljust(10).should be_kind_of(StringSpecs::MyString)
#    StringSpecs::MyString.new("foo").ljust(10, StringSpecs::MyString.new("x")).should be_kind_of(StringSpecs::MyString)
#
#    "".ljust(10, StringSpecs::MyString.new("x")).should be_kind_of(String)
#    "foo".ljust(10, StringSpecs::MyString.new("x")).should be_kind_of(String)
#
#  it "when padding is tainted and self is untainted returns a tainted string if and only if length is longer than self" do
#    "hello".ljust(4, 'X'.taint).tainted?.should be_false
#    "hello".ljust(5, 'X'.taint).tainted?.should be_false
#    "hello".ljust(6, 'X'.taint).tainted?.should be_true
