% plot samples from solutions
% 3dsolver main

inputdir = 'testdata';
outputroot = 'output-ramawks';

id = 7;
imagename = dir(fullfile(inputdir, num2str(id, '%d-*.mat')));
imagename = imagename.name(1:end-length('.jpg-relation.mat'));
% relation_mat = imagename.name;
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
% layout_samples = sample_layouts(layouts, num_layout_sample);
% if ~exist(outputdir, 'dir')
%     mkdir(outputdir);
% end
load(fullfile(outputdir, 'layout3d.mat'), 'layouts', 'layout_samples');
plot_layouts(config, layout_samples, outputdir);