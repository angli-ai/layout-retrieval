% eval exhaustive search

input_layout2d = '../3dsolver/output-ramawks/';

dataset = 'sunrgbd';
inputdir = fullfile('baseline-data', dataset);
outputdir = 'sunrgbd-output';
if ~exist('SUNRGBDMeta', 'var')
    load('/Users/ang/projects/layout3d/sunrgbd-dataset/SUNRGBDtoolbox/Metadata/SUNRGBDMeta.mat');
end

% load ground truth
detection_dir = fullfile('detection-box', dataset);
if ~exist('gt', 'var')
gt = load(fullfile(detection_dir, 'gtbbox_test.mat'));
end
if ~exist('detection', 'var')
detection = load(fullfile(detection_dir, 'detection_test.mat'));
end

if ~exist(outputdir, 'dir')
    mkdir(outputdir);
end

for id = 1:15

inputmat = dir(fullfile(input_layout2d, num2str(id, '%d-*')));
assert(length(inputmat) == 1);
imagename = inputmat.name;
if exist(fullfile(outputdir, [imagename '.mat']), 'file')
    continue;
end
inputmat = fullfile(input_layout2d, inputmat.name, 'layout2d.mat');
if ~exist(inputmat, 'file')
    continue;
end
load(inputmat, 'layout2d');
if isempty(layout2d)
    continue;
end

index = strfind(imagename, '-');
gt_index = str2num(imagename(index(1)+1:end));

match_config = [];
match_config.n_scale = 5;
match_config.scales = 0.5:1/match_config.n_scale:1;
match_config.n_x = 10;
match_config.n_y = 10;
Ntest = length(detection.detection);

final_score = [];
rank = 0;
visualize = false;
for k = 1:Ntest
%     k = 24;
    rgbpath = fullfile('../../../sunrgbd-dataset/', SUNRGBDMeta(k).rgbpath(18:end));
    I = imread(rgbpath);
    det = detection.detection{k};
    index = det.bg_conf < det.conf;
    det = det(index, :);
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
%     if max(S) > 0.260765
%         rank = rank + 1;
%     end
%     fprintf(1, '%d: %f, gt rank %d\n', k, max(S), rank);
%     break;
end
max_score = max(final_score, [], 2);
[~, ranks] = sort(max_score);
[~, ranks] = sort(ranks);
fprintf(1, '%d: rank %d\n', id, Ntest-ranks(gt_index)+1);
save(fullfile(outputdir, imagename), 'final_score');
end