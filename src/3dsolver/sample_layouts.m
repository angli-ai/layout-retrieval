function output = sample_layouts(layouts, num)
% method: random
Nlayouts = length(layouts);
num = min(Nlayouts, num);
index = randperm(Nlayouts, num);
output = {};
for i = 1:num
    l = layouts{index(i)};
    Ndim = size(l, 1);
    l = l(:, 1) + rand(Ndim, 1) .* (l(:, 2) - l(:, 1));
    % camera orientation
    ax = rand * 90;
    az = normrnd(30, 10);
    dist = rand * 5 + 5;
    
    layout = [];
    layout.objs = reshape(l, 4, Ndim/4);
    layout.cam_ax = ax;
    layout.cam_az = az;
    layout.cam_d = dist;
    cam_height = 1.75;
    layout.cam = [dist * cos(ax/180*pi), dist * sin(ax/180*pi), cam_height];
    layout.focal = 1;
    output = [output layout];
end