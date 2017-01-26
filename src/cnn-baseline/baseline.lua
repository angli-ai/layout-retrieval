
require 'tds'
require 'loadcaffe'
local utils = require 'utils'
local libimage = require 'image'

local vggnet = loadcaffe.load('VGG_ILSVRC_19_layers_deploy.prototxt' , 'VGG_ILSVRC_19_layers.caffemodel')
vggnet:evaluate()
for i = 1,3 do vggnet:remove() end

local head = torch.load('models/cnn-predicate.t7')
local net = nn.Sequential():add(vggnet):add(head):add(nn.SoftMax())
net:float()

local dic = torch.load('models/dic.t7')

local queryjsondir = 'data/testjsons/query'
local refjsondir = 'data/testjsons/reference'
local testimgdir = 'data/testimages'
for f in paths.iterfiles(queryjsondir) do
   local data = utils.loadjson(queryjsondir..'/'..f)
   local gtid = data.gtid
   for i = 1, 5050 do
      local filename = string.format('%s/%05d.json', refjsondir, i)
      local det = utils.loadjson(filename)
      local newdet = {}
      for j = 1, #det do
         if det[j].conf > 0.5 then
            table.insert(newdet, det[j])
         end
      end
      det = newdet
      local imgpath = string.format('%s/%05d.jpg', testimgdir, i)
      local img = libimage.load(imgpath)
      for _, rel in ipairs(data.relationships) do
         local confs = {}
         for j = 1, #det do
            if det[j].classname == rel.subject then
               local start = rel.subject == rel.object and j + 1 or 1
               for k = start, #det do
                  if det[k].classname == rel.object then
                     -- data.predicate
                     local bbox = utils.bboxUnion(det[j].bbox, det[k].bbox)
                     print(rel.subject, rel.object)
                     --[[
                     local newimg = libimage.drawRect(img, det[j].bbox[1], det[j].bbox[2], det[j].bbox[3], det[j].bbox[4], {lineWidth = 3, color = {255, 0, 0}})
                     newimg = libimage.drawRect(newimg, det[k].bbox[1], det[k].bbox[2], det[k].bbox[3], det[k].bbox[4], {lineWidth = 3, color = {0, 255, 0}})
                     --]]
                     local input = libimage.crop(img, bbox[1], bbox[2], bbox[3], bbox[4])
                     input = utils.resizeSquare{
                        input = input,
                        padding = true,
                        outputsize = 224,
                     }
                     input = utils.preprocess(input)
                     input = input:float()
                     local output = net:forward(input)
                     local conf = output[dic.predicate2idx[rel.predicate]]
                     --print(rel.subject, rel.object, rel.predicate, conf)
                     table.insert(confs, conf)
                     --require('fb.debugger').enter()
                     --libimage.display(im)
                  end
               end
            end
         end
         local confvec = torch.Tensor(confs)
         local sorted_confvec = confvec:sort(1, true)
         require('fb.debugger').enter()
      end
      --[[
      local dispim = libimage.load(imgpath)
      for k,v in ipairs(newdet) do
         print(k, v.classname)
         dispim = libimage.drawRect(dispim,
            v.bbox[1], v.bbox[2], v.bbox[3], v.bbox[4],
            {lineWidth = 3, color = {255, 0, 0}})
      end
      libimage.display(dispim)
      --]]
   end
end
