local argcheck = require 'argcheck'
local libimage = require 'image'

local utils = {}
utils.bboxUnion = function(bbox1, bbox2)
   -- xmin, ymin, xmax, ymax
   assert(bbox1[1] < bbox1[3] and bbox2[1] < bbox2[3], 'error: '..bbox2[1]..' < '..bbox2[3]..' ')
   assert(bbox1[2] < bbox1[4] and bbox2[2] < bbox2[4])
   return {
      math.min(bbox1[1], bbox2[1]),
      math.min(bbox1[2], bbox2[2]),
      math.max(bbox1[3], bbox2[3]),
      math.max(bbox1[4], bbox2[4])
   }
end

utils.loadjson = function(filepath)
   local json = require 'cjson'
   local file = io.open(filepath)
   local data = json.decode(file:read('*a'))
   io.close(file)
   return data
end

utils.resizeSquare = argcheck{
   {name='input', type='torch.*Tensor'},
   {name='outputsize', type='number', default=224},
   {name='padding', type='boolean', default=false},
   {name='paddingRGB', type='table', default={0,0,0}},
   call = function(input, outputsize, padding, paddingRGB)
      local libimage = require 'image'
      local nc, height, width = unpack(input:size():totable())
      local temp
      if width < height then
         temp = libimage.scale(input, width / height * outputsize, outputsize)
      else
         temp = libimage.scale(input, outputsize, height / width * outputsize)
      end
      local output = input.new(nc, outputsize, outputsize)
      if padding then
         for k = 1, nc do
            if paddingRGB then
               output[k]:fill(paddingRGB[k])
            else
               local meanval = temp[k]:mean()
               output[k]:fill(meanval)
            end
         end
      else
         output:fill(0)
      end
      local xoffset = math.floor((outputsize - temp:size(3)) / 2)
      local yoffset = math.floor((outputsize - temp:size(2)) / 2)
      output[{{}, {yoffset + 1, yoffset + temp:size(2)}, {xoffset + 1, xoffset + temp:size(3)}}]:copy(temp)
      return output
      
   end
}

-- crop a set of bounding boxes
utils.cropUnionBox = argcheck{
   {name='input', type='torch.*Tensor'},
   {name='boxes', type='table'},
   {name='padding', type='boolean', default=false},
   {name='paddingRGB', type='table', default={0,0,0}},
   {name='outputsize', type='number', default=224},
   call = function(input, boxes, padding, paddingRGB, outputsize)
      assert(#boxes > 0)
      local unionbox = boxes[1]
      for k = 2, #boxes do
         unionbox = utils.bboxUnion(unionbox, boxes[k])
      end
      local libimage = require 'image'
      local cropim = libimage.crop(input, unionbox[1], unionbox[2], unionbox[3], unionbox[4])
      local output
      if padding then
         output = input.new(cropim:size())
         assert(#paddingRGB == 3)
         for k = 1, 3 do
            output[k]:fill(paddingRGB[k])
         end
         for _,v in ipairs(boxes) do
            output[{{}, {v[2]-unionbox[2]+1, v[4]-unionbox[2]}, {v[1]-unionbox[1]+1, v[3]-unionbox[1]}}]:copy(
               cropim[{{}, {v[2]-unionbox[2]+1, v[4]-unionbox[2]}, {v[1]-unionbox[1]+1, v[3]-unionbox[1]}}])
         end
      else
         output = cropim
      end
      return output
   end
}

-- convert RGB image to BGR with mean subtracted.
utils.preprocess = function(img)
   local mean_pixel = torch.DoubleTensor({103.939, 116.779, 123.68})
   local perm = torch.LongTensor{3, 2, 1}
   img = img:index(1, perm):mul(256.0)
   mean_pixel = mean_pixel:view(3, 1, 1):expandAs(img)
   img:add(-1, mean_pixel)
   return img
end

return utils
