#!/usr/bin/env lua

function is_prime(x)
    if x == 1 then return false end
    if x == 2 then return true end
    if x % 2 == 0 then return false end
    for k=3,math.floor(math.sqrt(x)),2 do
        if x % k == 0 then
           return false
        end
    end
    return true
end


x = os.time()
print("The current time is: " .. x)
while not is_prime(x) do
    x = x - 1
end
print("The most recent prime is: " .. x)
