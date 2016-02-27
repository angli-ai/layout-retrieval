% convert detection boxes to 6x5 layout matrix
function layout = detection2layout(boxes)
% boxes:  6x1 cell array
layout = zeros(6,5);
for furniture_idx = 1:6 
    % if detection is not empty
    if ~isempty(boxes{furniture_idx}.bbox) && boxes{furniture_idx}.topbox(1,end)>=-0.3
        
        layout(furniture_idx,1:4) = boxes{furniture_idx}.topbox(1,1:4);
        layout(furniture_idx,5) = boxes{furniture_idx}.topbox(1,end);
    end
end

end
