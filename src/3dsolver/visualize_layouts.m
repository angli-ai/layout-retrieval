% visualize layouts

% convert layout3d to layout2d

% 3dsolver main

inputdir = '../data/relations-sunrgbd-all';
outputroot = '../test';
num_layout_sample = 1;

imagenames = dir(fullfile(outputroot, '*'));
imagenames = setdiff({imagenames(:).name}, {'.', '..'});
for i = 1:length(imagenames)
imagename = imagenames{i};
disp(imagename);
outputdir = fullfile(outputroot, imagename);
data = load(fullfile(outputdir, 'layout3d.mat'), 'config', 'layouts', 'layout_samples');

if isempty(data.layouts)
    continue;
end


config = data.config;
layouts = data.layouts;
layout_samples = sample_layouts(config, layouts, num_layout_sample);
if ~exist(outputdir, 'dir')
    mkdir(outputdir);
end
save(fullfile(outputdir, 'layout3d.mat'), 'config', 'layouts', 'layout_samples');

plot_layouts(config, layout_samples, outputdir);
end