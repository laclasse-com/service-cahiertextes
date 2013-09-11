########################################
# Private methods of RubyJS base object
########################################


# helper method to get an arguments object
#
# @return [Arguments]
# @private
#
RubyJS.argify = -> arguments

# Creates a wrapper method that calls a functional style
# method with this as the first arguments. Tries to avoid apply.
#
#     callFunctionWithThis(_s.ljust)
#     // creates a function similar to this:
#     // function (len, pad) {
#     //    return _s.ljust(this, len, pad)
#     // }
#
# This can be used to extend native classes/prototypes with functional
# methods.
#
#     String.prototype.capitalize = callFunctionWithThis(_s.capitalize)
#     "foo".capitalize() // => "Foo"
#
# @private
#
RubyJS.callFunctionWithThis = callFunctionWithThis = (func) ->
  () ->
    a = arguments
    switch arguments.length
      when 0 then func(this)
      when 1 then func(this, a[0])
      when 2 then func(this, a[0], a[1])
      when 3 then func(this, a[0], a[1], a[2])
      when 4 then func(this, a[0], a[1], a[2], a[3])
      when 5 then func(this, a[0], a[1], a[2], a[3], a[4])
      when 6 then func(this, a[0], a[1], a[2], a[3], a[4], a[5])
      # Slow fallback when passed more than 6 arguments.
      else func.apply(null, [this].concat(nativeSlice.call(arguments, 0)))


# RubyJS specific helper methods
# @private
RubyJS.ensure_args_length = __ensure_args_length = (args, length) ->
  throw R.ArgumentError.new() unless args.length is length


# Finds, removes and returns the last block/function in arguments list.
# This is a destructive method.
#
# @example Use like this
#   foo = (args...) ->
#     console.log( args.length )     # => 2
#     block = __extract_block(args)
#     console.log( args.length )     # => 1
#     other = args[0]
#
# @private
#
RubyJS.extract_block = __extract_block = (args) ->
  idx = args.length
  while --idx >= 0
    return args.pop() if args[idx]?.call?
  null


