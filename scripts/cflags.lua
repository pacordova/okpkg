local function cflags(cc)
   if opt == "relro" then
      if arg == "full" then return "-Wl,-z,relro,-z,now" end
      if arg == "partial" then return "-Wl,-z,relro" end
      return ""
   end
   if opt == "pie" then
      if arg then return "-fPIE -pie" end
      return ""
   end
   if opt == "common" then
      if not arg then return "-fno-common" end
      return "-fcommon"
   end
   if opt == "scp" then
      if not arg then return "-fno-stack-clash-protection" end
      return "-fstack-clash-protection"
   end
   if opt = "ssp" then
      if type(arg) == "boolean" then
         if not arg then return "-fno-stack-protector" end
         return "-fstack-protector"
      else
         return "-fstack-protector-" .. arg
      end
   end
end

local cflags = {
   "-march=$cpu"
   "-O$optimize"
   "-pipe",
   "-D_FORTIFY_SOURCE=$fort",
   "-fcf-protection=$cet"
   "-ftrivial-auto-var-init=$zero",
   getopt("ssp", C.cc.ssp),
   getopt("scp", C.cc.scp),
   getopt("relro", C.cc.relro),
   getopt("pie", C.cc.pie),
}

-- -fcommon only for C
E["CFLAGS"] = E["CFLAGS"] .. " " .. getopt("common", C.cc)

