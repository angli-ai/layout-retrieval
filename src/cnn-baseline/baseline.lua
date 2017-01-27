
require 'nn'
require 'cunn'
require 'cudnn'
require 'loadcaffe'
local tds = require 'tds'
local utils = require 'utils'
local libimage = require 'image'
local xlua = require 'xlua'

local vggnet = loadcaffe.load('VGG_ILSVRC_19_layers_deploy.prototxt' , 'VGG_ILSVRC_19_layers.caffemodel')
vggnet:evaluate()
for i = 1,3 do vggnet:remove() end


local netversion = 'v2'
local dic = torch.load('output-v2/dic.t7')
local modelpath = 'output-v2/model-90.t7'
local head = torch.load(modelpath)
local net = nn.Sequential():add(vggnet):add(head):add(nn.SoftMax())
net:cuda()

local queryjsondir = 'data/testjsons/query'
local refjsondir = 'data/testjsons/reference'
local testimgdir = 'data/testimages'
local ntest = 5050
local ranks, scores = tds.hash(), tds.hash()
local netinput = torch.CudaTensor()
for f in paths.iterfiles(queryjsondir) do
   local data = utils.loadjson(queryjsondir..'/'..f)
   local gtid = data.gtid
   local myscores = torch.Tensor(ntest):zero()
   for i = 1, ntest do
      local filename = string.format('%s/%05d.json', refjsondir, i)
      local det = utils.loadjson(filename)
      local newdet = {}
      for j = 1, #det do
         if det[j].bbox[1] < det[j].bbox[3] and det[j].bbox[2] < det[j].bbox[4] and det[j].conf > 0.5 then
            table.insert(newdet, det[j])
         end
      end
      det = newdet
      local imgpath = string.format('%s/%05d.jpg', testimgdir, i)
      local img = libimage.load(imgpath)
      -- compute scores for scene graph
      local score = 0
      for _, rel in ipairs(data.relationships) do
         local confs = {}
         for j = 1, #det do
            if det[j].classname == rel.subject then
               local start = rel.subject == rel.object and j + 1 or 1
               for k = start, #det do
                  if det[k].classname == rel.object then
                     -- data.predicate
                     local bbox = utils.bboxUnion(det[j].bbox, det[k].bbox)
                     --print(rel.subject, rel.object)
                     --[[
                     local newimg = libimage.drawRect(img, det[j].bbox[1], det[j].bbox[2], det[j].bbox[3], det[j].bbox[4], {lineWidth = 3, color = {255, 0, 0}})
                     newimg = libimage.drawRect(newimg, det[k].bbox[1], det[k].bbox[2], det[k].bbox[3], det[k].bbox[4], {lineWidth = 3, color = {0, 255, 0}})
                     --]]
                     local input
                     local vggmeanRGB = {123.68/256, 116.779/256, 103.939/256}
                     if netversion == 'v1' then
                        input = libimage.crop(img, bbox[1], bbox[2], bbox[3], bbox[4])
                        input = utils.resizeSquare{
                           input = input,
                           padding = true,
                           outputsize = 224,
                        }
                     elseif netversion == 'v2' then
                        input = utils.cropUnionBox{
                           input = img,
                           boxes = {det[j].bbox, det[k].bbox},
                           padding = true,
                           paddingRGB = vggmeanRGB
                        }
                        input = utils.resizeSquare{
                           input = input,
                           padding = true,
                           outputsize = 224,
                           paddingRGB = vggmeanRGB,
                        }
                     end
                     input = utils.preprocess(input)
                     netinput:resize(input:size()):copy(input)
                     local output = net:forward(netinput):float()
                     local conf = output[dic.predicate2idx[rel.predicate]]
                     --print(rel.subject, rel.object, rel.predicate, conf)
                     table.insert(confs, conf)
                     --require('fb.debugger').enter()
                     --libimage.display(im)
                  end
               end
            end
         end
         if #confs > 0 then
            local confvec = torch.Tensor(confs)
            local sorted_confvec = confvec:sort(1, true)
            local num = math.min(#confs, rel.count)
            local relscore = sorted_confvec[{{1, num}}]:sum()
            score = score + relscore
         end
      end
      myscores[i] = score
      xlua.progress(i, ntest)
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
   ranks[gtid] = math.floor((myscores:gt(myscores[gtid]):sum() + myscores:ge(myscores[gtid]):sum())/2) + 1
   print(gtid, ranks[gtid])
   scores[gtid] = myscores
end
torch.save('result-'..netversion..'.t7', {ranks = ranks, scores = scores})
