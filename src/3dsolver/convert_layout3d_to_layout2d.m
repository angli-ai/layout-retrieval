% convert layout3d to layout2d

% 3dsolver main

inputdir = 'testdata';
outputroot = 'output-ramawks-2';

for id = 16:21
imagename = dir(fullfile(outputroot, num2str(id, '%d-*')));
% imagename = imagename.name(1:end-length('.jpg-relation.mat'));
imagename = imagename.name;
% relation_mat = imagename.name;
% imagename = 'test';
relation_mat = [imagename '.jpg-relation.mat'];
outputdir = fullfile(outputroot, imagename);
data = load(fullfile(outputdir, 'layout3d.mat'), 'config', 'layouts', 'layout_samples');

if ~isfield(data, 'config')
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

    data.config = config;
end

plot_layouts(data.config, data.layout_samples, outputdir);
end