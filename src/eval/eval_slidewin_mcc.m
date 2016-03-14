% eval exhaustive search
function eval_slidewin_mcc(job_id, num_jobs)

if nargin < 1
    job_id = 1;
    num_jobs = 1;
else
    job_id = str2num(job_id);
    num_jobs = str2num(num_jobs);
end

fprintf(1, '%d/%d\n', job_id, num_jobs);

dataset = 'sunrgbd';
use_gt = false;
use_thresh = false;
thresh = 0.5;

input_layout2d = '../data/output-sunrgbd-20/';
outputdir = '../eval-data/output-sunrgbd-20-det';

inputdir = fullfile('baseline-data', dataset);
if ~exist('SUNRGBDMeta', 'var')
    load('detection-box/SUNRGBDMeta.mat');
end

% load ground truth
detection_dir = fullfile('detection-box', dataset);
if ~exist('gt', 'var')
% gt = load(fullfile(detection_dir, 'gtbbox_test.mat'));
end
if ~exist('detection', 'var')
detection = load(fullfile(detection_dir, 'detection_test.mat'));
end

if ~exist(outputdir, 'dir')
    mkdir(outputdir);
end

visualize = false;

dirlist = dir(fullfile(input_layout2d, '*'));
dirlist = {dirlist(:).name};

for id = 1:length(dirlist)
    if dirlist{id}(1) == '.'
        continue;
    end
    if mod(id, num_jobs) ~= job_id - 1
        continue;
    end
%     id = 10;
    %assert(length(inputmat) == 1);
    imagename = dirlist{id};
    disp(imagename);
    if exist(fullfile(outputdir, [imagename '.mat']), 'file')
        continue;
    end
    inputmat = fullfile(input_layout2d, imagename, 'layout2d.mat');
    if ~exist(inputmat, 'file')
        continue;
    end
    load(inputmat, 'layout2d');
    if isempty(layout2d)
        continue;
    end

    index = strfind(imagename, '-');
    if isempty(index)
        gt_index = str2num(imagename);
    else
        gt_index = str2num(imagename(index(1)+1:end));
    end

    match_config = [];
    match_config.n_scale = 5;
    match_config.scales = 0.5:1/match_config.n_scale:1;
    match_config.n_x = 10;
    match_config.n_y = 10;
    Ntest = length(detection.detection);

    final_score = [];
    gt_score = [];
    rank = 0;
    for k = 1:Ntest
%         k = 249;
        if visualize
            rgbpath = fullfile('../../../sunrgbd-dataset/', SUNRGBDMeta(k).rgbpath(18:end));
            I = imread(rgbpath);
        end
        if use_gt
            det = gt.gtbbox_test{k};
            det.conf = ones(size(det, 1));
        else
            det = detection.detection{k};
            index = det.bg_conf < det.conf;
            if use_thresh
                index = index & det.conf > thresh;
                det.conf(:) = 1.0;
            end
            det = det(index, :);
        end
        S = [];
        for i = 1:length(layout2d)
            layout = layout2d{i};
            tmp = layout.Y1;
            layout.Y1 = -layout.Y2;
            layout.Y2 = -tmp;
            layout = normalize_composition(layout);
            [score, s, x, y] = exhaustive_match(layout, det, match_config);
            S = [S, max(score)];
            if visualize
                h = imshow(I);
                [~, index] = max(score);
                for j = 1:size(layout, 1)
                    classname = layout.classname{j};
                    bb = layout(j, 2:end);
                    bbox = [bb.X1, bb.Y1, bb.X2-bb.X1, bb.Y2-bb.Y1] * s(index) + [x(index), y(index), 0, 0];
    %                 bbox = [bb.X1, bb.Y1, bb.X2-bb.X1, bb.Y2-bb.Y1];
                    plotbbox_with_classname(bbox, classname, 1);
                    hold on;
                end
                hold off;
            end
        end
        final_score = [final_score; S];
        if k == gt_index
            gt_score = max(S);
            fprintf(1, '%d: gt score %f\n', id, gt_score);
            rank = sum(max(final_score, [], 2) > gt_score + eps);
        end
         if ~isempty(gt_score) && max(S) > gt_score + eps
             rank = rank + 1;
         end
        fprintf(1, '%d: %f, gt rank %d\n', k, max(S), rank);
    %     break;
    end
    max_score = max(final_score, [], 2);
    [~, ranks] = sort(max_score);
    [~, ranks] = sort(ranks);
    fprintf(1, 'query %d: rank %d\n', id, Ntest-ranks(gt_index)+1);
    save(fullfile(outputdir, imagename), 'final_score');
%     break;
% break;
end
