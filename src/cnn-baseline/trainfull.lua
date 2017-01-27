require 'SunRelDataset'
require 'loadcaffe'
local libimage = require 'image'
local tnt = require 'torchnet'
local utils = require 'utils'
local tds = require 'tds'
local optimlib = require 'optimlib'
require 'nn'
require 'cunn'

local cmd = torch.CmdLine()
cmd:option('-reload', '', 'reload model and resume training')
cmd:option('-outputdir', '.', 'output directory')
cmd:option('-lr', 0.1, 'learning rate')
cmd:option('-nCPU', 4, 'num of cpu')
cmd:option('-epochsize', 500000, 'epoch size')
cmd:option('-head', 'linear', 'linear | mlp')
cmd:option('-batchsize', 16, 'batch size')
cmd:option('-trunkbatchsize', 4, 'batch size for trunk')
cmd:option('-usecpu', false, 'use cpu')
cmd:option('-maxepoch', 90, 'max # of epochs')
cmd:option('-depth', 22, 'depth of resnet')
cmd:option('-fixed_lr_decay', false, 'fixed lr decay')
cmd:option('-smooth_lr_decay', false, 'smooth lr decay')
cmd:option('-lr_decay', 100, 'lr decay')
cmd:option('-weight_decay', 0.0001, 'weight decay')
cmd:option('-nesterov', 0.9, 'nesterov momentum')
cmd:option('-momentum', 0, 'non-nesterov momentum')
cmd:option('-disable_test', false, 'disable test')
cmd:option('-save_latest_only', false, 'only save latest model')
local config = cmd:parse(arg or {})

print(config)

-- set up learning rates
local lrtensor = torch.FloatTensor(config.maxepoch)
if config.fixed_lr_decay then
   local log_lr_decay = math.log10(config.lr_decay)
   for epoch = 1, config.maxepoch do
      local decay
      if config.smooth_lr_decay then
         decay = log_lr_decay * (epoch - 1) / math.max(self.maxepoch - 1, 1)
      else
         decay = math.floor((1 + log_lr_decay) * (epoch - 1) / config.maxepoch)
      end
      lrtensor[epoch] = config.lr / math.pow(10, decay)
   end
else
   lrtensor:fill(config.lr)
end
config.lr = lrtensor

local vggnet = loadcaffe.load('VGG_ILSVRC_19_layers_deploy.prototxt' , 'VGG_ILSVRC_19_layers.caffemodel')
vggnet:evaluate()
for i = 1,3 do vggnet:remove() end

local predicates = utils.loadjson('data/trainjsons/train_predicates.json')

local predicate2idx = tds.hash()
for k,v in pairs(predicates) do
   predicate2idx[v] = k
end
if not paths.dirp(config.outputdir) then paths.mkdir(config.outputdir) end
torch.save(config.outputdir..'/dic.t7', {predicates=predicates, predicate2idx=predicate2idx})

local usebg = false -- include background that is outside of the boxes.

local datatransformer = function(x)
   local libimage = require 'image'
   assert(x.unionbox)
   local vggmeanRGB = {123.68/256, 116.779/256, 103.939/256}
   local input
   if usebg then
      input = libimage.crop(x.input, x.unionbox[1], x.unionbox[2], x.unionbox[3], x.unionbox[4])
   else
      input = utils.cropUnionBox{
         input = x.input,
         boxes = {x.subjectbbox, x.objectbbox},
         padding = true,
         paddingRGB = vggmeanRGB
      }
   end
   input = utils.resizeSquare{
      input = input,
      padding = true,
      outputsize = 224,
      paddingRGB = vggmeanRGB,
   }
   local utils = require 'utils'
   x.input = utils.preprocess(input)
   --[[
   vggnet:forward(input)
   x.input = vggnet.output:clone()
   --]]
   x.target = torch.Tensor{predicate2idx[x.predicate]}
   return x
end

local dataset = tnt.TransformDataset{
   dataset = SunRelDataset{mode='train'},
   transform = datatransformer,
}

local testdataset
if not config.disable_test then
   testdataset = tnt.BatchDataset{
      dataset = tnt.TransformDataset{
         dataset = SunRelDataset{mode='test'},
         transform = datatransformer,
      },
      batchsize = config.batchsize,
   }
end

local traindataset = tnt.BatchDataset{
   dataset = tnt.ShuffleDataset{
      dataset = dataset,
   },
   batchsize = config.batchsize,
}

local function getIterator(dataset, mode)
   mode = mode or 'train'
   if mode == 'train' then
      assert(torch.isTypeOf(dataset.dataset, 'tnt.ShuffleDataset'))
      dataset.dataset:resample()
   end
   return config.nCPU == 1
   and tnt.DatasetIterator{
      dataset = dataset,
   } or tnt.ParallelDatasetIterator{
      nthread = config.nCPU,
      init = function()
         require 'torchnet'
         require 'SunRelDataset'
      end,
      closure = function()
         return dataset
      end
   }
end

local featsize = 4096
local ntargets = #predicates
local net = nn.Sequential()
net:add(vggnet)

if config.head == 'linear' then
   net:add(nn.Linear(featsize, ntargets))
elseif config.head == 'mlp' then
   local nhidden = 128
   net:add(nn.Linear(featsize, nhidden))
   :add(nn.ReLU())
   :add(nn.Linear(nhidden, ntargets))
end
local criterion = nn.CrossEntropyCriterion()

local epoch = 0
-- test engine
local testengine = tnt.SGDEngine()
local testmeter = tnt.AverageValueMeter()
local testclerr = tnt.ClassErrorMeter{topk = {1}}
testengine.hooks.onStart = function(state)
   testmeter:reset()
   testclerr:reset()
   cnt = 0
end
local igpu, igpu2 = torch.CudaTensor(), torch.CudaTensor()
testengine.hooks.onSample = function(state)
   igpu:resize(state.sample.input:size()):copy(state.sample.input)
   if igpu:nDimension() == 4 then
      local nc = state.sample.input:size(1)
      igpu2:resize(nc, 4096)
      for k = 1, nc, config.trunkbatchsize do
         local endidx = math.min(nc, k+config.trunkbatchsize-1)
         igpu2[{{k,endidx},{}}]:copy(vggnet:forward(igpu[{{k,endidx},{},{},{}}]))
      end
   else
      igpu2:resize(1, 4096):copy(vggnet:forward(igpu))
   end
   state.sample.input = igpu2
end
testengine.hooks.onForwardCriterion = function(state)
   testmeter:add(state.criterion.output)
   testclerr:add(state.network.output, state.sample.target)
   cnt = cnt + 1
   xlua.progress(cnt, testdataset:size())
end
testengine.hooks.onEnd = function(state)
   print(string.format('test | epoch %d: avg. loss: %.4f; avg. error: %.4f',
      epoch, testmeter:value(), testclerr:value{k=1}))
end

local engine = tnt.SGDEngine()
local meter = tnt.AverageValueMeter()
local clerr = tnt.ClassErrorMeter{topk = {1}}
local timer = tnt.TimeMeter{unit = true}
engine.hooks.onStartEpoch = function(state)
   timer:reset()
   meter:reset()
   clerr:reset()
   cnt = 0
   state.lr = config.lr[state.epoch + 1]
end

local minloss, maxloss = 1e100, 0

engine.hooks.onForwardCriterion = function(state)
   if state.criterion.output < minloss then minloss = state.criterion.output end
   if state.criterion.output > maxloss then maxloss = state.criterion.output end
   if maxloss > minloss * 1000 then
      print(maxloss, minloss)
      error('weird loss values: maxloss > minloss * 1000. reduce learning rate?')
   end
   -- if cnt < 5 then print(state.criterion.output) end
   meter:add(state.criterion.output)
   clerr:add(state.network.output, state.sample.target)
   cnt = cnt + 1
   xlua.progress(cnt, traindataset:size())
end

engine.hooks.onBackward = function(state)
   optimlib.weightDecay{network=state.network, decay=config.weight_decay}
   optimlib.momentum{network=state.network, momentum=config.momentum}
   optimlib.nesterovMom{network=state.network, momentum=config.nesterov}
end

engine.hooks.onEndEpoch = function(state)
   print(string.format('epoch %d: avg. loss: %.4f; avg. error: %.4f',
      state.epoch, meter:value(), clerr:value{k=1}))
   print()
   state.iterator = getIterator(traindataset)
   epoch = state.epoch
   if not config.disable_test then
      testengine:test{
         network = state.network,
         iterator = getIterator(testdataset, 'test'),
         criterion = state.criterion,
      }
   end
   if config.save_latest_only then
      torch.save(config.outputdir..'/model-last.t7', state.network)
   else
      torch.save(config.outputdir..'/model-'..state.epoch..'.t7', state.network)
   end
   collectgarbage()
   collectgarbage()
end

if not config.usecpu then
   require 'cudnn'
   net = net:cuda()
   criterion = criterion:cuda()
   vggnet = vggnet:cuda()
   local igpu, tgpu = torch.CudaTensor(), torch.CudaLongTensor()
   engine.hooks.onSample = function(state)
      igpu:resize(state.sample.input:size()):copy(state.sample.input)
      tgpu:resize(state.sample.target:size()):copy(state.sample.target)
      state.sample.input = igpu
      state.sample.target = tgpu
   end
end

engine:train{
   network = net,
   iterator = getIterator(traindataset),
   criterion = criterion,
   lr = config.lr[1],
   maxepoch = config.maxepoch,
}
