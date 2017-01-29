return function (ntargets)
   require 'nn'
   require 'cunn'
   require 'cudnn'
   require 'loadcaffe'
   local vggnet = loadcaffe.load('VGG_ILSVRC_19_layers_deploy.prototxt' , 'VGG_ILSVRC_19_layers.caffemodel')
   vggnet:training()
   for i = 1,3 do vggnet:remove() end

   local featsize = 4096 + 300 * 2

   local model = nn.Sequential()
   model:add(nn.ParallelTable():add(vggnet):add(nn.Identity()))
   model:add(nn.JoinTable(-1))
   model:add(nn.Linear(featsize, ntargets))
   return model
end
