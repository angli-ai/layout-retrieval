% eccv_analysis

dataset = 'sunrgbd';

input_layout2d = '../data/output-sunrgbd-1-5/';
datapath = '/Users/ang/projects/layout3d/sunrgbd-dataset/SUNRGBDtoolbox/gtimgs';

outputdir = 'eccv-supp-sunrgbd';
if ~exist(outputdir, 'dir')
    mkdir(outputdir);
end

filelist = dir(fullfile(input_layout2d, '*'));
filelist = {filelist(:).name};

scorepath = '../eval-data/output-sunrgbd-1-5-det';
use_thresh = false;
thresh = 0.5;

detection_dir = fullfile('detection-box', dataset);
if ~exist('detection', 'var') || ~strcmp(detection.dataset, dataset)
detection = load(fullfile(detection_dir, 'detection_test.mat'));
detection.dataset = dataset;
end

imagepath_det = '/Users/ang/projects/layout3d/sunrgbd-dataset/sunrgbd_fastrcnn/detection-test-vis';
imagepath_gt = '/Users/ang/projects/layout3d/sunrgbd-dataset/SUNRGBDtoolbox/vis';
imagepath = '/Users/ang/projects/layout3d/sunrgbd-dataset/SUNRGBDtoolbox/gtimgs';

match_config = [];
match_config.n_scale = 5;
match_config.scales = 0.5:1/match_config.n_scale:1;
match_config.n_x = 10;
match_config.n_y = 10;
for ii = 1:length(filelist)
    if filelist{ii}(1) == '.'
        continue;
    end
imageid = filelist{ii};
if exist(fullfile(outputdir, imageid), 'dir')
    continue;
end

inputmat = fullfile(input_layout2d, imageid, 'layout2d.mat');
if ~exist(inputmat, 'file')
    continue;
end

clear layout2d
load(inputmat, 'layout2d');
% imageid = '2-00054';
index = strfind(imageid, '-');
if isempty(index)
    gtid = str2num(imageid);
else
    gtid = str2num(imageid(index+1:end));
end
    
if ~exist(fullfile(scorepath, [imageid, '.mat']), 'file')
    continue;
end
scores = load(fullfile(scorepath, [imageid, '.mat']));
scores = max(scores.final_score, [], 2);
bar(scores);

[~, rank_id] = sort(scores, 'descend');
[~, rank] = sort(rank_id);

% print gt score
gtscore = scores(gtid);
fprintf(1, 'GT (#%d) score: %f\n', gtid, gtscore);

% print gt rank
gtrank = rank(gtid);
fprintf(1, 'GT (#%d) rank: %d\n', gtid, gtrank);

topks = 1:5;

if gtrank > 5
    topks = [topks gtrank];
end
% show top 1 image
for topk = topks
top_id = rank_id(topk);
det_image_path = fullfile(imagepath_det, num2str(top_id, 'vis_%05d.jpg'));
% det_image = imread(fullfile(imagepath_det, num2str(top_id, 'vis_%05d.jpg')));
% gt_image = imread(fullfile(imagepath_gt, num2str(top_id, 'vis_%05d.jpg')));
% det_/imagegt = imread(fullfile(imagepath_det, num2str(gtid, 'vis_%05d.jpg')));

k = top_id;

rgbpath = fullfile(imagepath, num2str(k, '%05d.jpg'));

I = imread(rgbpath);
J = I;
det = detection.detection{k};
index = det.bg_conf < det.conf;
if use_thresh
    index = index & det.conf > thresh;
    det.conf(:) = 1.0;
end
classnames = unique(layout2d{1}.classname);
for i = 1:length(det.classname)
    if isempty(find(strcmp(det.classname{i}, classnames), 1))
        index(i) = 0;
    end
end
det = det(index, :);


opt = [];
opt.score = -inf;
opt.s = [];
opt.x = [];
for i = 1:length(layout2d)
    layout = layout2d{i};
    tmp = layout.Y1;
    layout.Y1 = -layout.Y2;
    layout.Y2 = -tmp;
    layout = normalize_composition(layout);
    [score, s, x, y, iou, conf] = exhaustive_match(layout, det, match_config);
%     S = [S, max(score)];
    if max(score) > max(opt.score)
        opt.i = i;
        opt.score = score;
        opt.s = s;
        opt.x = x;
        opt.y = y;
        opt.iou = iou;
        opt.conf = conf;
        opt.layout = layout;
    end
end


score = opt.score;
if isempty(opt.s)
    opt.i = 1;s = 0; x = 1; y = 1; opt.iou = 0; opt.conf = 0;
    layout = [];
else
    s = opt.s;
    x = opt.x;
    y = opt.y;
layout = opt.layout;
end
    h1 = figure(1);
    imshow(I);
    [maxscore, index] = max(score);
    iou = opt.iou(:, index);
    conf = opt.conf(:, index);
    ncolor = length(classnames);
    colors = lines(ncolor);
    for j = 1:size(layout, 1)
        classname = layout.classname{j};
        color = find(strcmp(classname, classnames));
        bb = layout(j, 2:end);
        bbox = [bb.X1, bb.Y1, bb.X2-bb.X1, bb.Y2-bb.Y1] * s(index) + [x(index), y(index), 0, 0];
%                 bbox = [bb.X1, bb.Y1, bb.X2-bb.X1, bb.Y2-bb.Y1];
        str = sprintf('%s\n(iou:%.2f,conf:%.2f)', classname, iou(j), conf(j));
        str = classname;
        plotbbox_with_classname_only(bbox, str, colors(color, :), 5);
        hold on;
    end
    hold off;
    h2 = figure(2);
    imshow(J);
    for j = 1:size(det, 1)
        classname = det.classname{j};
        color = find(strcmp(classname, classnames));
        bb = det(j, 2:end);
        bbox = [bb.X1, bb.Y1, bb.X2-bb.X1, bb.Y2-bb.Y1];
%                 bbox = [bb.X1, bb.Y1, bb.X2-bb.X1, bb.Y2-bb.Y1];
        str = sprintf('%s\n%.2f', classname, det.conf(j));
        plotbbox_with_classname_only(bbox, str, colors(color, :), 5);
        hold on;
    end
    hold off;
    suffix = '';
    if top_id == gtid
        suffix = '-gt';
        sz = size(I);
        figure(h1);
        rectangle('Position', [1 1 sz(2)-1 sz(1)-1], 'edgecolor', [0 .618 0], 'linewidth', 10);
    end
    outputpath = fullfile(outputdir, imageid, [num2str(topk, '%d') suffix '.png']);
    if ~exist(fullfile(outputdir, imageid), 'dir')
        mkdir(fullfile(outputdir, imageid));
    end
%     title(num2str(maxscore, 'Score = %.2f'));
    saveas(h1, outputpath);
    
    det_image_outputpath = fullfile(outputdir, imageid, [num2str(topk, '%d') suffix '-det.jpg']);
    saveas(h2, det_image_outputpath);
    
    layout3d_img_path = fullfile(input_layout2d, imageid, num2str(opt.i, 'layout-%d-3d.jpg'));
    layout3d_output = fullfile(outputdir, imageid, [num2str(topk, '%d') suffix '-3d.jpg']);
    copyfile(layout3d_img_path, layout3d_output);
end
end