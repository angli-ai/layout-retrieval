% cvpr: ablation analysis on # of samples

% # of viewpoint samples

numlayouts = 5;
numviews = 5;
randomvers = 10;
rng(randomvers);

root = '../cvpr17data/output-cvpr173dgp';
outputdir = ['../cvpr17data/ablations/sun-' num2str(numlayouts) '-' num2str(numviews) '-v' num2str(randomvers)];
outputdir = ['../cvpr17data/output-cvpr173dgp-v' num2str(randomvers)];
if ~exist(outputdir, 'dir')
    mkdir(outputdir)
end
filelist = dir(root);
filelist = {filelist(:).name};
filelist = setdiff(filelist, {'.', '..', '.DS_Store'});

num = [];
for i = 1:length(filelist)
    filename = fullfile(root, filelist{i}, 'layout3d.mat');
    if ~exist(filename, 'file')
        continue;
    end
    data = load(filename);
    num(i) = length(data.layouts);
    layout_samples = cvpr17_ablation_sample_layouts(data.config, data.layouts, numlayouts, numviews);
    plot_layouts(data.config, layout_samples, fullfile(outputdir, filelist{i}), false);
    disp(i)
end