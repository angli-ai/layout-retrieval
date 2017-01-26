require 'SunRelDataset'
libimage = require 'image'

--print('qt', qt)
--[[
if not qt then
   libimage.display = function() end
end
--]]

dataset = SunRelDataset{mode='train'}

print('#dataset', dataset:size())

idx = torch.random(dataset:size())
for idx = 1, dataset:size() do
data = dataset:get(idx)

print(data.subject, data.predicate, data.object)

if data.predicate == 'left' then

subbox = data.subjectbbox
objbox = data.objectbbox

unionbox = SunRelDataset.bboxUnion(subbox, objbox)
unionbox = data.unionbox

lineWidth = 6

im = libimage.drawRect(data.input, subbox[1], subbox[2], subbox[3], subbox[4], {
   lineWidth = lineWidth,
   color = {0, 255, 0}
})
im = libimage.drawRect(im, objbox[1], objbox[2], objbox[3], objbox[4], {
   lineWidth = lineWidth,
   color = {255, 0, 0}
})
im = libimage.drawRect(im, unionbox[1], unionbox[2], unionbox[3], unionbox[4], {
   lineWidth = 1,
   color = {0, 0, 255},
})
libimage.display(im)
print(unionbox)
cropim = libimage.crop(im, unionbox[1], unionbox[2], unionbox[3], unionbox[4])
libimage.display(cropim)

input = libimage.crop(data.input, unionbox[1], unionbox[2], unionbox[3], unionbox[4])

require 'loadcaffe'
vggnet = loadcaffe.load('VGG_ILSVRC_19_layers_deploy.prototxt' , 'VGG_ILSVRC_19_layers.caffemodel')
vggnet:evaluate()

utils = require 'utils'
output = utils.resizeSquare{
   input = input,
   padding = true,
   outputsize = 224,
}
feature = vggnet:forward(output)
libimage.display(output)
-- print(feature)

break

end
end
