
class ArrayMethods extends EnumerableMethods
  # Checks if arr is an Array or can be coerced to an array
  # using valueOf()
  #
  # @example
  #   _a.isArray([])     // => true
  #   _a.isArray({})     // => false
  #   _a.isArray("")     // => false
  #   _a.isArray(null)   // => false
  #   // Arguments are not arrays
  #   function () { return _a.isArray(arguments) }(1,2)  // => false
  #   // Checks if valueOf() returns an array
  #   _a.isArray({valueOf: function(){return [];}}) // => true
  #
  isArray: __isArr



  # Checks if arrays have the same elements.
  #
  # @example
  #   _a.equals([1,2], [1,2])         // => true
  #   _a.equals([1,2,[3]], [1,2,[3]]) // => true
  #
  equals: (arr, other) ->
    return true  if arr is other
    return false unless other?

    if __isArr(other)
      other = __arr(other)
    else
      return false

    return false unless arr.length is other.length

    i = 0
    total = i + arr.length
    while i < total
      return false unless __equals(arr[i], other[i])
      i += 1

    true


  append: (arr, obj) ->
    arr.push(obj)
    arr


  # Set Intersection—Returns a new array containing elements common to the two
  # arrays, with no duplicates.
  #
  # @example
  #   _a.intersection([1,1,3,5],[1,2,3])  // => [1, 3]
  #
  intersection: (arr, other) ->
    other = __arr(other)
    out   = []

    _arr.each arr, (el) ->
      out.push(el) if _arr.include(other, el)

    _arr.uniq(out)


  # Comparison—Returns an integer (-1, 0, or +1) if this array is less than,
  # equal to, or greater than other_ary. Each object in each array is compared
  # (using <=>). If any value isn’t equal, then that inequality is the return
  # value. If all the values found are equal, then the return is based on a
  # comparison of the array lengths. Thus, two arrays are “equal” according to
  # Array#<=> if and only if they have the same length and the value of each
  # element is equal to the value of the corresponding element in the other
  # array.
  #
  # @example
  #   _a.cmp(["a","a","c"], ["a","b","c"]) // => -1
  #   _a.cmp([1,2,3,4,5,6], [1,2])         // => +1
  #
  cmp: (arr, other) ->
    return null unless other?
    try
      other = __arr(other)
    catch e
      return null

    return 0 if _arr.equals(arr, other)

    len = arr.length
    other_total = other.length
    # Thread.detect_recursion arr, other do
    i = 0
    total = if other_total < len then other_total else len

    while total > i
      diff = __cmp(arr[i], other[i])
      return diff unless diff == 0
      i += 1

    # subtle: if we are recursing on that pair, then let's
    # no go any further down into that pair;
    # any difference will be found elsewhere if need be
    __cmp(len, other_total)


  # Returns the element at index. A negative index counts from the end of
  # arr. Returns nil if the index is out of range. See also Array#[].
  #
  # @example
  #   a = [ "a", "b", "c", "d", "e" ]
  #   _a.at(a, 0)     #=> "a"
  #   _a.at(a, -1)    #=> "e"
  #
  # @return [Object]
  #
  at: (arr, index) ->
    if index < 0
      arr[arr.length + index]
    else
      arr[index]


  # When invoked with a block, yields all combinations of length n of elements
  # from ary and then returns ary itself. The implementation makes no
  # guarantees about the order in which the combinations are yielded.
  #
  # If no block is given, an enumerator is returned instead.
  #
  # @example
  #   arr = [1, 2, 3, 4]
  #   _a.combination(arr, 1, function (arr) { _puts(arr) })
  #   _a.combination(arr, 1)  #=> [[1],[2],[3],[4]]
  #   _a.combination(arr, 2)  #=> [[1,2],[1,3],[1,4],[2,3],[2,4],[3,4]]
  #   _a.combination(arr, 3)  #=> [[1,2,3],[1,2,4],[1,3,4],[2,3,4]]
  #   _a.combination(arr, 4)  #=> [[1,2,3,4]]
  #   _a.combination(arr, 0)  #=> [[]] # one combination of length 0
  #   _a.combination(arr, 5)  #=> []   # no combinations of length 5
  #
  # @return Array
  #
  combination: (arr, num, block) ->
    return __enumerate(_arr.combination, [arr, num]) unless block?.call?

    num = __int(num)
    len = arr.length


    if num is 0
      block([])
    else if num == 1
      _arr.each arr, (args...) ->
        block.call(arr, args)

    else if num == len
      block(arr.slice(0))

    else if num >= 0 && num < len
      num    = num
      stack  = (0 for i in [0..num+1])
      chosen = []
      lev    = 0
      done   = false
      stack[0] = -1
      until done
        chosen[lev] = arr[stack[lev+1]]
        while lev < num - 1
          lev += 1
          stack[lev+1] = stack[lev] + 1
          chosen[lev] = arr[stack[lev+1]]

        block.call(arr, chosen.slice(0))
        lev += 1

        # this is begin ... while
        done = lev == 0
        stack[lev] += 1
        lev = lev - 1
        while (stack[lev+1] + num == len + lev + 1)
          done = lev == 0
          stack[lev] += 1
          lev = lev - 1
    arr


  # Returns a copy of arr with all nil elements removed.
  #
  # @example
  #   _a.compact([ "a", null, "b", null, "c", null ])
  #   // => [ "a", "b", "c" ]
  #
  # @return [Array]
  #
  compact: (arr) ->
    # one liner: _arr.select arr, (el) -> el?
    ary = []
    for el in arr
      ary.push(el) if el?
    ary


  # Deletes items from arr that are equal to obj. If any items are found,
  # returns obj. If the item is not found, returns nil. If the optional code
  # block is given, returns the result of block if the item is not found. (To
  # remove nil elements and get an informative return value, use compact!)
  #
  # @example
  #   a = [ "a", "b", "b", "b", "c" ]
  #   _a.delete(a, "b")                   // => "b"
  #   a                                   // => ["a", "c"]
  #   _a.delete(a, "z")                   // => nil
  #   _a.delete(a, "z", function () { return 'not found'} )
  #   // => "not found"
  #
  # @destructive
  #
  # @return [Object]
  #
  delete: (arr, obj, block) ->
    deleted = []

    i = 0
    len = arr.length
    while i < len
      if __equals(obj, arr[i])
        deleted.push(i)
      i += 1

    if deleted.length > 0
      arr.splice(i,1) for i in deleted.reverse()
      return obj

    if block then block() else null


  # Deletes the element at the specified index, returning that element, or nil
  # if the index is out of range. See also Array#slice!.
  #
  # @example
  #    arr = ['ant','bat','cat','dog']
  #    _a.delete_at(arr, 2)    #=> "cat"
  #    arr                     #=> ["ant", "bat", "dog"]
  #    _a.delete_at(arr, 99)   #=> null
  #
  # @return obj or null
  #
  # @destructive
  delete_at: (arr, idx) ->
    idx = idx + arr.length if idx < 0
    return null if idx < 0 or idx >= arr.length
    arr.splice(idx, 1)[0]


  # Returns the first element, or the first n elements, of the enumerable. If
  # the enumerable is empty, the first form returns nil, and the second form
  # returns an empty array.
  #
  # @example
  #   arr = ['foo','bar','baz']
  #   _a.first(arr)     // => "foo"
  #   _a.first(arr, 2)  // => ["foo", "bar"]
  #   _a.first(arr, 10) // => ["foo", "bar", "baz"]
  #   _a.first([])      // => null
  #
  first: (arr, n) ->
    if n?
      _err.throw_argument() if n < 0
      arr.slice(0,n)
    else
      arr[0]


  # Returns a new array that is a one-dimensional flattening of this array
  # (recursively). That is, for every element that is an array, extract its
  # elements into the new array. If the optional level argument determines the
  # level of recursion to flatten.
  #
  # @example
  #   s = [ 1, 2, 3 ]
  #   t = [ 4, 5, 6, [7, 8] ]
  #   arr = [ s, t, 9, 10 ]     // => [[1, 2, 3], [4, 5, 6, [7, 8]], 9, 10]
  #   _a.flatten(arr)           // => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  #   arr = [ 1, 2, [3, [4, 5] ] ]
  #   _a.flatten(arr, 1)        // => [1, 2, 3, [4, 5]]
  #
  # @return [Array] flattened array
  #
  flatten: (arr, recursion = -1) ->
    arr = __arr(arr)
    ary = []

    len = arr.length
    idx = -1
    while (++idx < len)
      el = arr[idx]
      if recursion != 0 && __isArr(el)
        nativePush.apply(ary, _arr.flatten(el, recursion - 1))
      else
        ary.push(el)

    ary



  # Calls block once for each element in arr, passing that element as a
  # parameter.
  #
  # If no block is given, an enumerator is returned instead.
  #
  # @example
  #   a = [ "a", "b", "c" ]
  #   str = ""
  #   _a.each(arr, function (x) { str += x} )
  #   // str: 'abc'
  #
  #
  each: (arr, block) ->
    return arr unless block?

    block = Block.splat_arguments(block)

    idx = -1
    len = arr.length
    while ++idx < arr.length
      block(arr[idx])

    arr


  # each with a thisArg.
  #
  # @example
  #   arr = [ "a", "b", "c" ]
  #   acc = []
  #   _a.each_with_context(arr, acc, function (x) { this.push(x) } )
  #   // => ['a', 'b', 'c']
  #
  # @non-ruby
  #
  # @return thisArg
  #
  each_with_context: (arr, thisArg, block) ->
    return __enumerate(_arr.each_with_context, [arr, thisArg]) unless block?

    block = Block.splat_arguments(block)

    idx = -1
    len = arr.length
    while ++idx < arr.length
      block.call(thisArg, arr[idx])

    arr


  # Same as Array#each, but passes the index of the element instead of the
  # element itself.
  #
  # If no block is given, an enumerator is returned instead.
  #
  # @example
  #   arr = [ "a", "b", "c" ]
  #   _a.each_index(arr, function (x) { R.puts "#{x} -- " })
  #   // 0 --
  #   // 1 --
  #   // 2 --
  #
  each_index: (arr, block) ->
    return __enumerate(_arr.each_index, [arr]) unless block?

    idx = -1
    len = arr.length
    while ++idx < len
      block(idx)
    this


  get: (arr, b) ->
    _arr.slice(arr,b)


  # Returns true if arr contains no elements.
  #
  empty: (arr) ->
    arr.length is 0


  # Tries to return the element at position index. If the index lies outside
  # the array, the first form throws an IndexError exception, the second form
  # returns default, and the third form returns the value of invoking the
  # block, passing in the index. Negative values of index count from the end
  # of the array.
  #
  # @example
  #   arr = [ 11, 22, 33, 44 ]
  #   _a.fetch(arr, 1)               // => 22
  #   _a.fetch(arr, -1)              // => 44
  #   _a.fetch(arr, 4, 'cat')        // => "cat"
  #   _a.fetch(arr, 4, function (i) { return i*i; })  // => 16
  #
  fetch: (arr, idx, default_or_block) ->
    idx  = __int(idx)
    len  = arr.length
    orig = idx
    idx  = idx + len if idx < 0

    if idx < 0 or idx >= len
      return default_or_block(orig) if default_or_block?.call?
      return default_or_block   unless default_or_block is undefined

      _err.throw_index()

    arr[idx]



  # Fills array with obj or block.
  #
  #     _a.fill(arr, obj)                   → ary
  #     _a.fill(arr, obj, start [, length]) → ary
  #     _a.fill(arr, obj, range )           → ary
  #     _a.fill(arr, function (index) {})   → ary
  #     _a.fill(arr, start [, length],  (index) -> block  → ary
  #     # not yet implemented:
  #     _a.fill(arr, range, (index) -> block ) → ary
  #
  # The first three forms set the selected elements of arr (which may be the
  # entire array) to obj. A start of nil is equivalent to zero. A length of
  # nil is equivalent to arr.length. The last three forms fill the array with
  # the value of the block. The block is passed the absolute index of each
  # element to be filled. Negative values of start count from the end of the
  # array.
  #
  # @example
  #   arr = [ "a", "b", "c", "d" ]
  #   _a.fill(arr, "x")               // => ["x", "x", "x", "x"]
  #   _a.fill(arr, "z", 2, 2)         // => ["x", "x", "z", "z"]
  #   _a.fill(arr, "y", 0..1)         // => ["y", "y", "z", "z"]
  #   _a.fill(arr, (i) -> i*i         // => [0, 1, 4, 9]
  #   _a.fill(arr, -2, function (i) { return i*i*i; })   // => [0, 1, 8, 27]
  #
  # @todo implement fill(range, ...)
  #
  # @destructive
  #
  fill: (arr, args...) ->
    _err.throw_argument() if args.length == 0
    block = __extract_block(args)

    if block
      _err.throw_argument() if args.length >= 3
      one = args[0]; two = args[1]
    else
      _err.throw_argument() if args.length > 3
      obj = args[0]; one = args[1]; two = args[2]

    size = arr.length

    if one?.is_range?
      # TODO: implement fill with range
      _err.throw_not_implemented()

    else if one isnt undefined && one isnt null
      left = __int(one)
      left = left + size    if left < 0
      left = 0              if left < 0

      if two isnt undefined && two isnt null
        try
          right = __int(two)
        catch e
          _err.throw_argument("second argument must be a Fixnum")
        return arr if right is 0
        right = right + left
      else
        right = size
    else
      left  = 0
      right = size

    total = right

    if right > size # pad with nul if length is greater than array
      fill = _arr.__native_array_with__(right - size, null)
      arr.push.apply(arr, fill)
      total = right

    i = left
    if block
      while total > i
        v = block(i)
        arr[i] = if v is undefined then null else v
        i += 1
    else
      while total > i
        arr[i] = obj
        i += 1

    arr


  # Inserts the given values before the element with the given index (which
  # may be negative).
  #
  # @example
  #   arr = ['a','b','c','d']
  #   _a.insert(arr, 2, 99)         // => ["a", "b", 99, "c", "d"]
  #   _a.insert(arr, -2, 1, 2, 3)   // => ["a", "b", 99, "c", 1, 2, 3, "d"]
  #
  # @destructive
  #
  insert: (arr, idx) ->
    _err.throw_argument() if idx is undefined

    return arr if arguments.length == 2
    items = _coerce.split_args(arguments, 2)

    len = arr.length
    # Adjust the index for correct insertion
    idx = idx + len + 1 if idx < 0 # Negatives add AFTER the element

    # TODO: add message "#{idx} out of bounds"
    _err.throw_index() if idx < 0

    after  = arr.slice(idx)

    if idx > len
      for i in [len...idx]
        arr[i] = null

    len = 0
    for el, i in items
      if el != undefined
        arr[idx+i] = el
        len += 1

    for el, i in after
      arr[idx+len+i] = el

    arr



  # Returns a string created by converting each element of the array to a
  # string, separated by sep.
  #
  # @example
  #     arr = ['a', 'b', 'c']
  #     _a.join(arr)       // => "abc"
  #     _a.join(arr,null)  // => "abc"
  #     _a.join(arr,"-")   // => "a-b-c"
  #     # joins nested arrays
  #     _a.join([1,[2,[3,4]]], '.')      // => '1.2.3.4'
  #     # Default separator R['$,'] (in ruby: $,)
  #     R['$,']           // => null
  #     _a.join(arr)      // => "abc"
  #     R['$,'] = '|'     // => '|'
  #     _a.join(arr)      // => "a|b|c"
  #
  join: (arr, separator) ->
    return '' if arr.length == 0
    separator = R['$,']  if separator is undefined
    separator = ''       if separator is null
    nativeJoin.call(_arr.flatten(arr), separator)



  # Deletes every element of arr for which block evaluates to false. See also
  # Array#select!
  #
  # If no block is given, an enumerator is returned instead.
  #
  # @example
  #   arr = [1,2,3,4]
  #   _a.keep_if(arr, function (v) { return i < 3; } )  // => [1,2,3]
  #   _a.keep_if(arr, function (v) { return true; } )   // => [1,2,3,4]
  #
  # @todo make destructive
  #
  keep_if: (arr, block) ->
    return __enumerate(_arr.keep_if, [arr]) unless block?

    block = Block.splat_arguments(block)

    ary = []
    idx = -1
    len = arr.length
    while ++idx < len
      el = arr[idx]
      ary.push(el) unless __falsey(block(el))

    ary



  # Returns the last element(s) of arr. If the array is empty, the first form
  # returns nil.
  #
  # @example
  #   arr = [ "w", "x", "y", "z" ]
  #   _a.last(arr)       // => "z"
  #   _a.last(arr, 2)    // => ["y", "z"]
  #
  last: (arr, n) ->
    len = arr.length
    if n is undefined
      return arr[len-1]

    if len is 0 or n is 0
      return []

    _err.throw_argument("count must be positive") if n < 0

    n = len if n > len
    arr[-n.. -1]


  # Array Difference - Returns a new array that is a copy of the original
  # array, removing any items that also appear in other_ary. (If you need set-
  # like behavior, see the library class Set.)
  #
  # @note minus checks for identity using _a.include(el), which differs slightly
  #   from the reference which uses #hash and #eql?
  #
  # @example
  #   arr = [1, 1, 2, 2, 3, 3, 4, 5 ]
  #   _a.minus(arr, [1, 2, 4])
  #   // =>  [3, 3, 5]
  #
  # @todo recursive arrays not tested
  #
  minus: (arr, other) ->
    other = __arr(other)

    ary = []
    idx = -1
    len = arr.length
    while ++idx < len
      el = arr[idx]
      ary.push(el) unless _arr.include(other, el)

    ary


  # Repetition - With a String argument, equivalent to _a.join(str).
  # Otherwise, returns a new array built by concatenating the int copies of
  # arr.
  #
  # @example
  #   arr = [ 1, 2, 3 ]
  #   _a.multiply(arr, 3  ) // => [ 1, 2, 3, 1, 2, 3, 1, 2, 3 ]
  #   _a.multiply(arr, ",") // => "1,2,3"
  #
  multiply: (arr, multiplier) ->
    _err.throw_type() if multiplier is null

    if __isStr(multiplier)
      return _arr.join(arr, __str(multiplier))
    else
      multiplier = __int(multiplier)

      _err.throw_argument("count cannot be negative") if multiplier < 0

      total = arr.length
      if total is 0
        return []
      else if total is 1
        return arr.slice(0)

      ary = []
      idx = -1
      while ++idx < multiplier
        ary = ary.concat(arr)

      ary


  # Removes the last element from arr and returns it, or nil if the array is empty.
  #
  # If a number n is given, returns an array of the last n elements (or less)
  # just like array.slice!(-n, n) does.
  #
  # @example
  #   arr = [ "a", "b", "c", "d" ]
  #   _a.pop(arr,)     // => "d"
  #   _a.pop(arr,2)    // => ["b", "c"]
  #   arr              // => ["a"]
  #
  pop: (arr, many) ->
    if many is undefined
      arr.pop()
    else
      many = __int(many)
      _err.throw_argument("negative array size") if many < 0
      ary = []
      len = arr.length
      many = len if many > len
      while many--
        ary[many] = arr.pop()
      ary


  # Returns an array of all combinations of elements from all arrays. The
  # length of the returned array is the product of the length of arr and the
  # argument arrays. If given a block, product will yield all combinations and
  # return arr instead.
  #
  # @example
  #   _a.product( [1,2,3], [4,5])      // => [[1,4],[1,5],[2,4],[2,5],[3,4],[3,5]]
  #   _a.product( [1,2],   [1,2])      // => [[1,1],[1,2],[2,1],[2,2]]
  #   _a.product( [1,2], [3,4],[5,6])  // => [[1,3,5],[1,3,6],[1,4,5],[1,4,6],
  #                                    //      [2,3,5],[2,3,6],[2,4,5],[2,4,6]]
  #   _a.product( [1,2] )              // => [[1],[2]]
  #   _a.product( [1,2], [])           // => []
  #
  # @todo does not check if the result size will fit in an Array.
  #
  product: (arr, args...) ->
    result = []
    block = __extract_block(args)

    args = for a in args
      __arr(a)
    args = args.reverse()
    args.push(arr)

    # Implementation notes: We build a block that will generate all the
    # combinations by building it up successively using "inject" and starting
    # with one responsible to append the values.
    outer = _arr.inject args, result.push, (trigger, values) ->
      (partial) ->
        for val in values
          trigger.call(result, partial.concat(val))

    outer( [] )
    if block
      block_result = arr
      for v in result
        block_result.push(block(v))
      block_result
    else
      result


  # Append—Pushes the given object(s) on to the end of this array. This
  # expression returns the array i arr, so several appends may be chained
  # together.
  #
  # @example
  #   arr = [ "a", "b", "c" ]
  #   _a.push(arr, "d", "e", "f")
  #   #=> ["a", "b", "c", "d", "e", "f"]
  #
  push: (arr, elements...) ->
    arr.push.apply(arr, elements)
    arr


  # Searches through the array whose elements are also arrays. Compares obj
  # with the second element of each contained array using ==. Returns the
  # first contained array that matches. See also Array#assoc.
  #
  # @example
  #   arr = [[1, "one"], [2, "two"], [3, "three"], ["ii", "two"]]
  #   _a.rassoc(arr, "two")    // => [2, "two"]
  #   _a.rassoc(arr, "four")   // => nil
  #
  rassoc: (arr, obj) ->
    len = arr.length
    idx = -1
    while ++idx < len
      elem = arr[idx]
      try
        el = __arr(elem)
        if __equals(el[1], obj)
          return elem
      catch e
        null
    null


  # TODO: _a.replace


  # Same as Array#each, but traverses arr in reverse order.
  #
  # @example
  #   arr = [ "a", "b", "c" ]
  #   acc = []
  #   _a.reverse_each arr, (x) -> acc.push("#{x} ")
  #   acc // => ['c ', 'b ', 'a ']
  #
  reverse_each: (arr, block) ->
    return __enumerate(_arr.reverse_each, [arr]) unless block?

    block = Block.splat_arguments(block)

    idx = arr.length
    while idx--
      block(arr[idx])

    arr


  # Returns the index of the last object in arr == to obj. If a block is
  # given instead of an argument, returns index of first object for which
  # block is true, starting from the last object. Returns nil if no match is
  # found. See also Array#index.
  #
  # If neither block nor argument is given, an enumerator is returned instead.
  #
  # @example
  #   arr = [ "a", "b", "b", "b", "c" ]
  #   _a.rindex(arr, "b")             // => 3
  #   _a.rindex(arr, "z")             // => nil
  #   _a.rindex(arr, function (x) { return x == "b" } // => 3
  #
  # @note does not check if array has changed.
  #
  rindex: (arr, other) ->
    return __enumerate(_arr.rindex, [arr, other]) if other is undefined

    len = arr.length
    ridx = arr.length
    if other.call?
      block = Block.splat_arguments(other)
      while ridx--
        el = arr[ridx]
        unless __falsey(block(el))
          return ridx

    else
      # TODO: 2012-11-06 use a while loop with idx counting down
      while ridx--
        el = arr[ridx]
        if __equals(el, other)
          return ridx

    null



  # Returns new array by rotating arr so that the element at cnt in arr is
  # the first element of the new array. If cnt is negative then it rotates in
  # the opposite direction.
  #
  # @example
  #   arr = [ "a", "b", "c", "d" ]
  #   _a.rotate(arr)       # => ["b", "c", "d", "a"]
  #   arr                  # => ["a", "b", "c", "d"]
  #   _a.rotate(arr, 2)    # => ["c", "d", "a", "b"]
  #   _a.rotate(arr, -3)   # => ["b", "c", "d", "a"]
  #
  rotate: (arr, cnt) ->
    if cnt is undefined
      cnt = 1
    else
      cnt = __int(cnt)

    len = arr.length
    return arr  if len is 1
    return []   if len is 0

    idx = cnt % len

    # TODO: optimize
    sliced = arr.slice(0, idx)
    arr.slice(idx).concat(sliced)


  # Choose a random element or n random elements from the array. The elements
  # are chosen by using random and unique indices into the array in order to
  # ensure that an element doesn’t repeat itself unless the array already
  # contained duplicate elements. If the array is empty the first form returns
  # nil and the second form returns an empty array.
  #
  # If rng is given, it will be used as the random number generator.
  #
  # @example
  #   arr = [1,2,3]
  #   _a.sample(arr)      // => 2
  #   _a.sample(arr, 2)   // => [3,1]
  #   _a.sample(arr, 4)   // => [2,1,3]
  #
  # @todo range is not implemented yet
  #
  sample: (arr, n, range = undefined) ->
    len = arr.length
    return arr[__rand(len)] if n is undefined
    n = __int(n)
    _err.throw_argument() if n < 0

    n    = len if n > len

    ary = arr.slice(0)
    idx = -1
    while ++idx < n
      ridx = idx + __rand(len - idx) # Random idx
      tmp  = ary[idx]
      ary[idx]  = ary[ridx]
      ary[ridx] = tmp

    ary.slice(0, n)


  # Length of array.
  #
  # @example
  #   _a.size([])      // => 0
  #   _a.size([1,2])   // => 2
  #
  # @return [Number]
  #
  size: (arr) ->
    arr.length


  # Returns a new array with elements of this array shuffled.
  #
  # @example
  #   arr = [ 1, 2, 3 ]
  #   _a.shuffle(arr)     //=> [2, 3, 1]
  #
  shuffle: (arr) ->
    len = arr.length
    ary = new Array(len)
    idx = -1
    while ++idx < len
      rnd = idx + __rand(len - idx)
      tmp = arr[idx]
      ary[idx] = arr[rnd]
      ary[rnd] = tmp
    ary


  # Element Reference—Returns the element at index, or returns a subarray
  # starting at start and continuing for length elements, or returns a
  # subarray specified by range. Negative indices count backward from the end
  # of the array (-1 is the last element). Returns null if the index (or
  # starting index) are out of range.
  #
  # @example
  #     a = [ "a", "b", "c", "d", "e" ]
  #     _a.slice(arr, 2) +  arr[0] + arr[1] // => "cab"
  #     _a.slice(arr, 6)                    // => null
  #     _a.slice(arr, 1, 2)                 // => [ "b", "c" ]
  #     _a.slice(arr, _r(1,3))              // => [ "b", "c", "d" ]
  #     _a.slice(arr, _r(4,7))              // => [ "e" ]
  #     _a.slice(arr, _r(6,10))             // => null
  #     _a.slice(arr, -3, 3)                // => [ "c", "d", "e" ]
  #     # special cases
  #     _a.slice(arr, 5)                    // => null
  #     _a.slice(arr, 5, 1)                 // => []
  #     _a.slice(arr, _r(5,10))             // => []
  #
  # @todo Ranges not yet implemented correctly, use R.Range(...)
  #
  slice: (arr, idx, length) ->
    _err.throw_type() if idx is null
    size = arr.length

    if idx?.is_range?
      range = idx
      range_start = __int(range.begin())
      range_end   = __int(range.end()  )
      range_start = range_start + size if range_start < 0

      if range_end < 0
        range_end = range_end + size

      range_end   = range_end + 1 unless range.exclude_end()
      range_lenth = range_end - range_start
      return null if range_start > size  or range_start < 0
      return arr.slice(range_start, range_end)
    else
      idx = __int(idx)

    idx = size + idx if idx < 0
    # return @$String('') if is_range and idx.lteq(size) and idx.gt(length)

    if length is undefined
      return null if idx < 0 or idx >= size
      arr[idx]
    else
      length = __int(length)
      return null if idx < 0 or idx > size or length < 0
      arr.slice(idx, length + idx)


  # Assumes that arr is an array of arrays and transposes the rows and columns.
  #
  # @example
  #   arr = [[1,2], [3,4], [5,6]]
  #   _a.transpose(arr)  // => [[1, 3, 5], [2, 4, 6]]
  #
  transpose: (arr) ->
    return [] if arr.length == 0

    out = []
    max = null

    # TODO: dogfood
    for ary in arr
      ary = __arr(ary)
      max ||= ary.length

      # Catches too-large as well as too-small (for which #fetch would suffice)
      # _err.throw_index("All arrays must be same length") if ary.size != max
      _err.throw_index() unless ary.length == max

      idx = -1
      len = ary.length
      while ++idx < len
        out.push([]) unless out[idx]
        entry = out[idx]
        entry.push(ary[idx])

    out


  # Returns a new array by removing duplicate values in arr.
  #
  # @example
  #   arr = [ "a", "a", "b", "b", "c" ]
  #   _a.uniq(arr)      // => ["a", "b", "c"]
  #   // Not yet implemented:
  #   c = [ "a:def", "a:xyz", "b:abc", "b:xyz", "c:jkl" ]
  #   _a.uniq(c, function(s) { return s[/^\w+/] })
  #   // => [ "a:def", "b:abc", "c:jkl" ]
  #
  # @note Not yet correctly implemented. should use #eql on objects, but uses @include().
  #
  uniq: (arr) ->
    idx = -1
    len = arr.length
    ary = []

    while (++idx < len)
      el = arr[idx]
      ary.push(el) if ary.indexOf(el) < 0

    ary


  unshift: (arr, args...) ->
    args.concat(arr)


  # Set Union—Returns a new array by joining this array with other_ary,
  # removing duplicates.
  #
  # @example
  #   _a.union([ "a", "b", "c" ], [ "c", "d", "a" ])
  #   // => [ "a", "b", "c", "d" ]
  #
  union: (arr, other) ->
    _arr.uniq(arr.concat(__arr(other)))



  # Returns an array containing the elements in arr corresponding to the
  # given selector(s). The selectors may be either integer indices or ranges.
  # See also Array#select.
  #
  # @example
  #     arr = ['a', 'b', 'c', 'd', 'e', 'f']
  #     _a.values_at(arr, 1, 3, 5)        // => ['b', 'd', 'f']
  #     _a.values_at(arr, 1, 3, 5, 7)     // => ['b', 'd', 'f', null]
  #     _a.values_at(arr, -1, -3, -5, -7) // => ['f', 'd', 'b', null]
  #     // _a.values_at(arr, _r(1,3), _r(2,5, false))
  #
  # @todo not working with ranges
  #
  values_at: (arr) ->
    len = arguments.length
    ary = new Array(len - 1)
    idx = 1
    while idx < len
      ary[idx - 1] = _arr.at(arr, __int(arguments[idx])) || null
      idx += 1
    ary



  # ---- Enumerable implementations ------------------------


  find_index: (arr, value) ->
    len = arr.length
    idx = -1

    if typeof value is 'function' or (typeof value is 'object' && value.call?)
      block = Block.splat_arguments(value)
    else if value != null && typeof value is 'object'
      block = (el) -> __equals(value, el)
    else
      while ++idx < len
        return idx if arr[idx] == value
      return null

    while ++idx < len
      return idx if block(arr[idx])

    null


  map: (arr, block) ->
    callback = Block.splat_arguments(block)

    idx = -1
    len = arr.length
    ary = new Array(len)
    while ++idx < len
      ary[idx] = callback(arr[idx])

    ary

  # @alias #first
  take: @prototype.first


  # @private
  __native_array_with__: (size, obj) ->
    ary = nativeArray(__int(size))
    idx = -1
    while ++idx < size
      ary[idx] = obj
    ary


_arr = R._arr = (arr) ->
  new Chain(arr, _arr)


R.extend(_arr, new ArrayMethods())