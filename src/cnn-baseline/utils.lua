local argcheck = require 'argcheck'
local libimage = require 'image'

local utils = {}
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
   call = function(input, outputsize, padding)
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
            local meanval = temp[k]:mean()
            output[k]:fill(meanval)
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
