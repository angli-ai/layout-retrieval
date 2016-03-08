% baseline eval

dataset = 'sunrgbd';
inputdir = fullfile('baseline-data', dataset);
resultdir = 'sunrgbd-output-4';

% load ground truth
detection_dir = fullfile('detection-box', dataset);
if ~exist('gt', 'var')
gt = load(fullfile(detection_dir, 'gtbbox_test.mat'));
end
if ~exist('detection', 'var')
detection = load(fullfile(detection_dir, 'detection_test.mat'));
end

threshold = 0.5;
ntest = length(gt.gtbbox_test);
assert(ntest == length(detection.detection));

gt_counts = {};
det_counts = {};
det_counts_soft = {};
for i = 1:ntest
    gt_counts{i} = count_strings(gt.gtbbox_test{i}.classname);
    det_counts{i} = count_strings_thresh(detection.detection{i}, threshold);
    det_counts_soft{i} = count_strings_conf(detection.detection{i});
end

res_ranks = [];
gt_ranks = [];
det_ranks = [];
det_ranks_soft = [];
queries = {};

eps = 1e-9;

for id = 1:21
%     id = 17;
    inputmat = dir(fullfile(inputdir, num2str(id, '%d-*.mat')));
    assert(length(inputmat) == 1);
    inputmat = inputmat.name;

    index = strfind(inputmat, '-');
    imageid = inputmat(index(1)+1:index(2)-5);
    imageid = str2num(imageid);
    queryid = inputmat(1:index(2)-5);
    
    if exist(fullfile(resultdir, [inputmat(1:index(2)-5) '.mat']), 'file')
        result = load(fullfile(resultdir, inputmat(1:index(2)-5)));
        score_res = -max(result.final_score, [], 2);
    else
        score_res = [];
        continue;
    end
    
    
    queries = [queries queryid];

    inputdata = load(fullfile(inputdir, inputmat));
    for i = 1:length(inputdata)
        switch inputdata.classes{i}
            case 'garage-bin'
                inputdata.classes{i} = 'garbage_bin';
            case 'triple-sofa'
                inputdata.classes{i} = 'sofa';
        end
        inputdata.classes{i}(strfind(inputdata.classes{i}, '-')) = '_';
    end
    score_gt = [];
    score_det = [];
    score_det_soft = [];
    for i = 1:ntest
        score_gt(i) = baseline_compare(inputdata, gt_counts{i});
        score_det(i) = baseline_compare(inputdata, det_counts{i});
        score_det_soft(i) = baseline_compare(inputdata, det_counts_soft{i});
    end

%     A = randperm(ntest);
%     [~, B] = sort(A);
    score = score_gt(imageid);
    gt_ranks = [gt_ranks round((sum(score_gt < score - eps) + 1 + sum(score_gt < score + eps)) / 2)];
%     [score, rank] = sort(score_gt);
%     [~, rank] = sort(rank);
%     score = score(B(imageid));
%     gt_ranks(id) = rank(B(imageid));
    
%     [~, rank] = sort(score_det(A));
%     [~, rank] = sort(rank);
%     det_ranks(id) = rank(B(imageid));
    score = score_det(imageid);
    det_ranks = [det_ranks round((sum(score_det < score - eps) + 1 + sum(score_det < score + eps)) / 2)];
    
%     [~, rank] = sort(score_det_soft(A));
%     [~, rank] = sort(rank);
%     det_ranks_soft(id) = rank(B(imageid));
    score = score_det_soft(imageid);
    det_ranks_soft = [det_ranks_soft round((sum(score_det_soft < score - eps) + 1+ sum(score_det_soft < score + eps)) / 2)];
    
    if ~isempty(score_res)
        score = score_res(imageid);
        rank = round((sum(score_res < score - eps) + 1 + sum(score_res < score + eps)) / 2);
%         [~, rank] = sort(score_res(A));
%         [~, rank] = sort(rank);
%         res_ranks = [res_ranks rank(B(imageid))];
        res_ranks = [res_ranks rank];
    end
end
h = figure(1);
tableres = plot_curves({gt_ranks, det_ranks, det_ranks_soft, res_ranks}, ntest, {'gt', 'det', 'det soft', 'det w/ spatial'});
output = table(queries', gt_ranks', det_ranks', det_ranks_soft', res_ranks');
saveas(h, 'result.png');