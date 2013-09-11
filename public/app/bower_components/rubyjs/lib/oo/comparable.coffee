# The Comparable mixin is used by classes whose objects may be ordered. The
# class must define the <=> operator, which compares the receiver against
# another object, returning -1, 0, or +1 depending on whether the receiver is
# less than, equal to, or greater than the other object. If the other object
# is not comparable then the <=> operator should return nil. Comparable uses
# <=> to implement the conventional comparison operators (<, <=, ==, >=, and
# >) and the method between?.
#
class RubyJS.Comparable

  lt: (other) ->
    cmp = @cmp(other)
    throw R.TypeError.new() if cmp is null
    cmp < 0

  gt: (other) ->
    cmp = @cmp(other)
    throw R.TypeError.new() if cmp is null
    cmp > 0

  lteq: (other) ->
    cmp = @cmp(other)
    throw R.TypeError.new() if cmp is null
    cmp <= 0

  gteq: (other) ->
    cmp = @cmp(other)
    throw R.TypeError.new() if cmp is null
    cmp >= 0

  # Returns false if obj <=> min is less than zero or if anObject <=> max is
  # greater than zero, true otherwise.
  #
  # @example
  #     R(3).between(1, 5)               # => true
  #     R(6).between(1, 5)               # => false
  #     R(3).between(3, 3)               # => true
  #     R('cat').between('ant', 'dog')   # => true
  #     R('gnu').between('ant', 'dog')   # => false
  #
  between: (min, max) ->
    @gteq(min) and @lteq(max)


  # Equivalent of calling
  # R(a).cmp(b) but faster for natives.
  @cmp: __cmp


  # Same as cmp, but throws ArgumentError if it cannot
  # coerce elements.
  @cmpstrict: __cmpstrict


  # aliases
  gteq: @prototype.gteq