
require 'loadcaffe'
local vggnet = loadcaffe.load('VGG_ILSVRC_19_layers_deploy.prototxt' , 'VGG_ILSVRC_19_layers.caffemodel')
vggnet:evaluate()
for i = 1,3 do vggnet:remove() end

local head = torch.load('models/cnn-predicate.t7')

require('fb.debugger').enter()
