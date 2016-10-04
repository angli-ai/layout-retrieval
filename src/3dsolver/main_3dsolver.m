% 3dsolver main

inputdir = '../data/relations-sunrgbd-all';
outputroot = 'output-sun-mac';
if ~exist(outputroot, 'dir')
    mkdir(outputroot);
end

% id = 13;
% imagename = dir(fullfile(inputdir, num2str(id, '%d-*.mat')));
% imagename = imagename.name(1:end-length('.jpg-relation.mat'));
% relation_mat = imagename.name;
% imagename = 'test';
imagename = '16-00322';
relation_mat = [imagename '.jpg-relation.mat'];
outputdir = fullfile(outputroot, imagename);

relation = load(fullfile(inputdir, relation_mat));

% expand plural nouns and collect size/support info.
relation = relation_preprocess(relation);

% object models
objmodels = get_object_models();

global starttime
starttime = tic;

% set room config
room = [];
room.length = 5;
room.width = 5;
room.height = 5;

% set spatial relation config
spatial = [];
spatial.attach = 0.25;
spatial.near = 0.5;
spatial.mindist = 0.1;
spatial.shift_tol = 0.25;

config = [];
config.relation = relation;
config.objmodels = objmodels;
config.room = room;
config.spatial = spatial;
num_layout_sample = 5;
num_layout_sample_each = 5;
% compute layouts
timer = tic;
layouts = interval_branch_bound(config, num_layout_sample_each);
toc(timer);
if isempty(layouts)
    return;
end
% sample layouts
layout_samples = sample_layouts(config, layouts, num_layout_sample);
if ~exist(outputdir, 'dir')
    mkdir(outputdir);
end
save(fullfile(outputdir, 'layout3d.mat'), 'config', 'layouts', 'layout_samples');
plot_layouts(config, layout_samples, outputdir);