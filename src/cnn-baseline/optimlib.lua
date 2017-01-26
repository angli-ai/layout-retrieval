local argcheck = require 'argcheck'

local optim = {}

optim.weightDecay = argcheck{
   {name = 'network', type = 'nn.Container'},
   {name = 'decay', type = 'number'},
   call = function(network, decay)
      if decay > 0 then
         local modules = network:listModules()
         for _,m in pairs(modules) do
            if not torch.isTypeOf(m, 'nn.BatchNormalization') and
               not torch.isTypeOf(m, 'nn.SpatialBatchNormalization')
               and m.weight and m.gradWeight then
               -- no decay on biases or batchnorm affine mapping
               m.gradWeight:add(decay, m.weight)
            end
         end
      end
   end
}

optim.momentum = argcheck{
   {name = 'network', type = 'nn.Container'},
   {name = 'momentum', type = 'number'},
   call = function(network, momentum)
      if momentum > 0 then
         local modules = network:listModules()
         for _,m in pairs(modules) do
            for w,dw in pairs{weight='gradWeight', bias='gradBias'} do
               if m[w] and m[dw] then
                  m.__optimmom = m.__optimmom or {}
                  m.__optimmom[dw] = m.__optimmom[dw] or m[dw].new(m[dw]:size()):fill(0)
                  m.__optimmom[dw]:mul(momentum):add(1, m[dw])
                  m[dw]:copy(m.__optimmom[dw])
               end
            end
         end
      end
   end
}

optim.nesterovMom = argcheck{
   {name = 'network', type = 'nn.Container'},
   {name = 'momentum', type = 'number'},
   call = function(network, momentum)
      if momentum > 0 then
         local modules = network:listModules()
         for _,m in pairs(modules) do
            for w,dw in pairs{weight='gradWeight',bias='gradBias'} do
               if m[w] and m[dw] then
                  m.__optimmom = m.__optimmom or {}
                  m.__optimmom[dw] = m.__optimmom[dw] or m[dw].new(m[dw]:size()):fill(0)
                  m.__optimmom[dw]:mul(momentum):add(m[dw])
                  m[dw]:add(momentum, m.__optimmom[dw])
               end
            end
         end
      end
   end
}

optim.polyakAveraging = argcheck{
   {name = 'network', type = 'nn.Container'},
   call = function(network)
      local modules = network:listModules()
      for _,m in pairs(modules) do
         for _,w in pairs{'weight', 'bias'} do
            if m[w] then
               m.__optimpolyakepoch = m.__optimpolyakepoch or 0
               m.__optimavgparams = m.__optimavgparams or {}
               m.__optimavgparams[w] = m.__optimavgparams[w] or m[w].new(m[w]:size()):fill(0)
               m.__optimpolyakepoch = m.__optimpolyakepoch + 1
               local t = m.__optimpolyakepoch
               m.__optimavgparams[w]:mul(1-1/t):add(1/t,m[w])
            end
         end
      end
   end
}

optim.usePolyakAverage = argcheck{
   {name = 'network', type = 'nn.Container'},
   call = function(network)
      local modules = network:listModules()
      for _,m in pairs(modules) do
         for _,w in pairs{'weight','bias'} do
            if m[w] and m.__optimavgparams[w] then
               m[w]:copy(m.__optimavgparams[w])
            end
         end
      end
   end
}

return optim
