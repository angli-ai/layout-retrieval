% 3dsolver main

inputdir = 'testdata';
outputroot = 'output';
if ~exist(outputroot, 'dir')
    mkdir(outputroot);
end

imagename = '00024';
relation_mat = [imagename '.jpg-relation.mat'];
outputdir = fullfile(outputroot, imagename);

relation = load(fullfile(inputdir, relation_mat));

% expand plural nouns and collect size/support info.
relation = relation_preprocess(relation);

% object models
objmodels = get_object_models();

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
% compute layouts
layouts = interval_branch_bound(config);
% sample layouts
num_layout_sample = 5;
layout_samples = sample_layouts(layouts, num_layout_sample);
plot_layouts(config, layout_samples, outputdir);