dataset = '3dgp';
detection_dir = fullfile('../eval/detection-box', dataset);
if ~exist('detection', 'var')
    detection = load(fullfile(detection_dir, 'detection_test.mat'));
end
if ~exist('gt', 'var')
    gt = load(fullfile(detection_dir, 'gtbbox_test.mat'));
end

usegt = true;
relation_dir = '../cvpr17data/relations-cvpr173dgp';
rlist = dir(fullfile(relation_dir, '*.mat'));
rlist = {rlist(:).name};
thresh = true;
% load relprob
gtrank = [];
dataid = {};
scores = {};
gtid = [];
Nimg = size(detection.index, 2);

gt_counts = {};
det_counts = {};
threshold = 0.5;
ntest = length(rlist);
for i = 1:Nimg
    n = size(detection.detection{i}, 1);
    detection.detection{i}.bg_conf = -inf(n, 1);
    gt_counts{i} = count_strings(gt.gtbbox_test{i}.classname);
    det_counts{i} = count_strings_thresh(detection.detection{i}, threshold);
%     det_counts_soft{i} = count_strings_conf(detection.detection{i});
end
for i = 1:length(rlist)
    rel = load(fullfile(relation_dir, rlist{i}));
    idx = strfind(rlist{i}, '-');
    idx = idx(1);
    gtid = str2num(rlist{i}(1:idx-1));
    dataid{i} = gtid;
    
    input = [];
    input.classes = {};
    input.numbers = [];
    cnt = 0;
    for j = 1:size(rel.nouns, 2)
        num = str2num(rel.nouns{2, j});
        name = rel.nouns{1, j};
        idx = strfind(name, '-');
        name(idx) = '_';
        idx = idx(end);
        o = name(1:idx-1);
        if ~isempty(strfind(o, 'sofa'))
            o = 'sofa';
        end
        idx = find(strcmp(o, input.classes));
        if ~isempty(idx)
            input.numbers(idx) = input.numbers(idx) + num;
        else
            cnt = cnt + 1;
            input.classes{cnt} = o;
            input.numbers(cnt) = num;
        end
    end
    
    score_gt = [];
    score_det = [];
    for j = 1:Nimg
        score_gt(j) = baseline_compare(input, gt_counts{j});
        score_det(j) = baseline_compare(input, det_counts{j});
    end
    scores_gt{i} = score_gt;
    scores_det{i} = score_det;
    gtid(i) = gtid;
end
outputfilename = 'scores-baselinec-3dgp.mat';
save(outputfilename, 'dataid', 'scores_gt', 'scores_det', 'gtid');
