require 'tds'

local cmd = torch.CmdLine()
cmd:option('-input', '', 'result.t7')
local opt = cmd:parse(arg or {})

local data = torch.load(opt.input)

local ks = {1, 10, 50, 100, 500}
for _,k in ipairs(ks) do
   cnt = 0 
   for _,v in pairs(data.ranks) do 
      if v <= k then 
         cnt = cnt + 1 
      end 
   end 
   print(k, cnt/#data.ranks) 
end
