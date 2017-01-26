local tnt = require 'torchnet'
local argcheck = require 'argcheck'
local tds = require 'tds'
local libimage = require 'image'
local utils = require 'utils'

local dataset, parent = torch.class('SunRelDataset', 'tnt.Dataset')

dataset.__init = argcheck{
   {name='self', type='SunRelDataset'},
   {name='datapath', type='string', default='data/'},
   {name='mode', type='string'},
   call = function(self, datapath, mode)
      assert(mode == 'train')
      local imagepath = datapath..'/trainimages/'
      local annojson = datapath..'/train_relation_anno.json'
      local objectjson = datapath..'/train_objects.json'
      local predicatejson = datapath..'/train_predicates.json'
      local anno = utils.loadjson(annojson)
      local objects = utils.loadjson(objectjson)
      local predicates = utils.loadjson(predicatejson)
      self.anno = anno
      self.objects = objects
      self.predicates = predicates
      local imagedatasetpath = datapath..'/tntdataset/'
      if paths.dirp(imagedatasetpath) then
         -- use indexeddataset
         self.imagedataset = tnt.IndexedDataset{
            fields = {'image'},
            path = imagedatasetpath,
            mmap = true,
            mmapidx = true,
         }
         self.imagedatasetidx = torch.load(imagedatasetpath..'/index.t7')
      else
         self.imagepath = imagepath
      end
   end
}

function bboxUnion(bbox1, bbox2)
   -- xmin, ymin, xmax, ymax
   assert(bbox1[1] < bbox1[3] and bbox2[1] < bbox2[3])
   assert(bbox1[2] < bbox1[4] and bbox2[2] < bbox2[4])
   return {
      math.min(bbox1[1], bbox2[1]),
      math.min(bbox1[2], bbox2[2]),
      math.max(bbox1[3], bbox2[3]),
      math.max(bbox1[4], bbox2[4])
   }
end

dataset.get = argcheck{
   {name='self', type='SunRelDataset'},
   {name='idx', type='number'},
   call = function(self, idx)
      local data = self.anno[idx]
      local input
      if self.imagedataset then
         local imgidx = self.imagedatasetidx.file2idx[data.filename]
         local compressed = self.imagedataset:get(imgidx).image
         input = image.decompress(compressed, 3, 'double')
      else
         local imagepath = self.imagepath..'/'..data.filename
         input = libimage.load(imagepath)
      end
      local output = {input = input}
      for k,v in pairs(data) do
         output[k] = v
      end
      output.unionbox = bboxUnion(output.subjectbbox, output.objectbbox)
      return output
   end
}

dataset.size = argcheck{
   {name='self', type='SunRelDataset'},
   call = function(self)
      return #self.anno
   end
}

dataset.bboxUnion = argcheck{
   {name='bbox1', type='table'},
   {name='bbox2', type='table'},
   call = function(bbox1, bbox2)
      return bboxUnion(bbox1, bbox2)
   end
}
