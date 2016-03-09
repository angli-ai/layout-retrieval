function output = sample_layouts(config, layouts, num)
% method: random
assert(~isempty(layouts));
while length(layouts) < num
    layouts = [layouts, layouts];
end
Nlayouts = length(layouts);
index = randperm(Nlayouts, num);
output = {};

for i = 1:num
    l = layouts{index(i)};
    % solve camera direction
    Nobj = length(config.relation.nouns);
    mincam = 0;
    maxcam = 90;
    for j = 1:Nobj
        switch config.relation.class{j}
            case {'picture', 'door', 'mirror', 'whiteboard', 'tv'}
                if l(j*4, :) == 0
                    mincam = max(mincam, 30);
                    maxcam = min(maxcam, 90);
                elseif l(j*4, 1) == 1
                    mincam = max(mincam, 0);
                    maxcam = min(maxcam, 60);
                end
        end
    end
    Ndim = size(l, 1);
    l = l(:, 1) + rand(Ndim, 1) .* (l(:, 2) - l(:, 1));
    % camera orientation
    ax = rand * (maxcam - mincam) + mincam;
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