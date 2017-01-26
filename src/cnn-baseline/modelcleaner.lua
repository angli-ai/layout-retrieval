require 'nn'

function zeroDataSize(data)
  if type(data) == 'table' then
    for i = 1, #data do
      data[i] = zeroDataSize(data[i])
    end
  elseif type(data) == 'userdata' then
    data = torch.Tensor():typeAs(data)
  end
  return data
end

-- Resize the output, gradInput, etc temporary tensors to zero (so that the
-- on disk size is smaller)
function cleanupModel(node)
  if node.output ~= nil then
    node.output = zeroDataSize(node.output)
  end
  if node.gradInput ~= nil then
    node.gradInput = zeroDataSize(node.gradInput)
  end
  if node.finput ~= nil then
    node.finput = zeroDataSize(node.finput)
  end
  if node.input_slice then
     node.input_slice = zeroDataSize(node.input_slice)
  end
  if node.output_slice then
     node.output_slice = zeroDataSize(node.output_slice)
  end
  -- Recurse on nodes with 'modules'
  if (node.modules ~= nil) then
    if (type(node.modules) == 'table') then
      for i = 1, #node.modules do
        local child = node.modules[i]
        cleanupModel(child)
      end
    end
  end

  collectgarbage()
end

return cleanupModel
