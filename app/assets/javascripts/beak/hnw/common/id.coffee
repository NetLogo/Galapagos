MinID = 0
MaxID = (2 ** 32) - 1

# (Number) => Number
nextID = (num) ->
  if num is MaxID then MinID else num + 1

# (Number) => Number
prevID = (num) ->
  if num is MinID then MaxID else num - 1

# This logic's a bit funky, because we're supporting ID numbers wrapping
# back around. --Jason B. (10/29/21)
#
# (Number, Number) => Boolean
precedesID = (target, ref) ->
  maxDist     = 20
  wrappedDist = ((ref - target) + MaxID) % MaxID
  (target isnt ref) and
    wrappedDist >= MinID and
    wrappedDist < (MinID + maxDist)

# (Number, Number) => Boolean
succeedsID = (target, ref) ->
  precedesID(ref, target)

export { MaxID, MinID, nextID, precedesID, prevID, succeedsID }
