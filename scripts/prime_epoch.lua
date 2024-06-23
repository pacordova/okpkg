#!/usr/bin/env lua

local x

local function is_prime(x)
   if x == 1 then return false end
   if x == 2 then return true end
   if x % 2 == 0 then return false end
   for k=3,math.floor(math.sqrt(x)),2 do
       if x % k == 0 then return false end
   end
   return true
end

x = os.time()
print(string.format("The current time is: %s", x))
while not is_prime(x) do x = x - 1 end
print(string.format("The most recent prime is: %s", x))
