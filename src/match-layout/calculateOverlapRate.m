% calculate overlap rate:
% rate = area(box & groundtruth)/area(box | groundtruth)
%
% box: [xmin ymin xmax ymax]
% groundtruth: [xmin ymin xmax ymax]
function rate = calculateOverlapRate(box,groundtruth)
box = ceil(box);
groundtruth = ceil(groundtruth);


a = max(box(2),groundtruth(2));
b = min(box(4),groundtruth(4));
c = max(box(1),groundtruth(1));
d = min(box(3),groundtruth(3));

andArea = (b-a+1)*(d-c+1);

orArea = (box(4)-box(2)+1)*(box(3)-box(1)+1) + ...
    (groundtruth(4)-groundtruth(2)+1)*(groundtruth(3)-groundtruth(1)+1) - andArea;
if a>b || c>d
    rate = 0;
else
    rate = double(andArea)/double(orArea);
end


end
