return (function(x)
   local i = string.find(string.reverse(x), "/", 1, true)
   if i then return string.sub(x, #x+2-i) else return x end
end)
