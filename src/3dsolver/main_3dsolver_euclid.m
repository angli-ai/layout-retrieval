% 3dsolver main

function main_3dsolver_euclid(worker_id, num_workers)
if nargin < 1
    worker_id = 1;
    num_workers = 1;
end
inputdir = '../cvpr17data/relations-cvpr17sun-current';
outputroot = '../cvpr17data/output-cvpr17sun-current2';
suffix =  '.jpg-relation';
% suffix = '-relation';
if worker_id == 1 && ~exist(outputroot, 'dir')
    mkdir(outputroot);
end

% id = 13;
% imagename = dir(fullfile(inputdir, num2str(id, '%d-*.mat')));
% imagename = imagename.name(1:end-length('.jpg-relation.mat'));
% relation_mat = imagename.name;
% imagename = 'test';
% imagename = '1-00024';
filelist = dir(fullfile(inputdir, '*.mat'));
filelist = {filelist(:).name};
for i = 1:length(filelist)
    if mod(i, num_workers) ~= worker_id - 1
        continue;
    end
    relation_mat = filelist{i};
    disp(relation_mat);
    index = strfind(relation_mat, suffix);
    imagename = relation_mat(1:index(1)-1);
% relation_mat = [imagename '.jpg-relation.mat'];
outputdir = fullfile(outputroot, imagename);

if exist(outputdir, 'dir')
    continue;
end

relation = load(fullfile(inputdir, relation_mat));

if isempty(relation.nouns)
    continue;
end

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
global starttime
starttime = tic;
num_layout_sample = 20;
num_layout_sample_each = 20;
% compute layouts
mytimer = tic;
layouts = interval_branch_bound(config, num_layout_sample_each);
timecost = toc(mytimer);
% sample layouts
layout_samples = sample_layouts(config, layouts, num_layout_sample);
if ~exist(outputdir, 'dir')
    mkdir(outputdir);
end
save(fullfile(outputdir, 'layout3d.mat'), 'config', 'layouts', 'layout_samples', 'timecost');
plot_layouts(config, layout_samples, outputdir);
end
