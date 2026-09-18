return (function(x) 
   local i = string.find(string.reverse(x), "/", 1, true)
   if i then return string.sub(x, 1, #x-i) else return "." end
end)
