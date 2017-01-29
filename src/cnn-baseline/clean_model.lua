require 'nn'
require 'cunn'
require 'cudnn'
cleaner = require 'modelcleaner'
model = torch.load('output-v4/model-last.t7')
model:evaluate()
cleaner(model)
model:float()
torch.save('output-v4/model-deploy.t7', model)
