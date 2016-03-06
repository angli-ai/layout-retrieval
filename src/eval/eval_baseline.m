% baseline eval

dataset = 'sunrgbd';
inputdir = fullfile('baseline-data', dataset);
resultdir = 'sunrgbd-output';

% load ground truth
detection_dir = fullfile('detection-box', dataset);
if ~exist('gt', 'var')
gt = load(fullfile(detection_dir, 'gtbbox_test.mat'));
end
if ~exist('detection', 'var')
detection = load(fullfile(detection_dir, 'detection_test.mat'));
end

threshold = 0.75;
ntest = length(gt.gtbbox_test);
assert(ntest == length(detection.detection));

gt_counts = {};
det_counts = {};
for i = 1:ntest
    gt_counts{i} = count_strings(gt.gtbbox_test{i}.classname);
    det_counts{i} = count_strings_thresh(detection.detection{i}, threshold);
end

res_ranks = [];

for id = 1:15
    inputmat = dir(fullfile(inputdir, num2str(id, '%d-*.mat')));
    assert(length(inputmat) == 1);
    inputmat = inputmat.name;

    index = strfind(inputmat, '-');
    imageid = inputmat(index(1)+1:index(2)-5);
    imageid = str2num(imageid);
    
    if exist(fullfile(resultdir, [inputmat(1:index(2)-5) '.mat']), 'file')
        result = load(fullfile(resultdir, inputmat(1:index(2)-5)));
        score_res = -max(result.final_score, [], 2);
    else
        score_res = [];
    end

    inputdata = load(fullfile(inputdir, inputmat));
    score_gt = [];
    score_det = [];
    for i = 1:ntest
        score_gt(i) = baseline_compare(inputdata, gt_counts{i});
        score_det(i) = baseline_compare(inputdata, det_counts{i});
    end

    A = randperm(ntest);
    [~, B] = sort(A);
    [~, rank] = sort(score_gt(A));
    [~, rank] = sort(rank);
    gt_ranks(id) = rank(B(imageid));
    
    [~, rank] = sort(score_det(A));
    [~, rank] = sort(rank);
    det_ranks(id) = rank(B(imageid));
    
    if ~isempty(score_res)
        [~, rank] = sort(score_res(A));
        [~, rank] = sort(rank);
        res_ranks = [res_ranks rank(B(imageid))];
    end
end
h = figure(1);
plot_curves({gt_ranks, det_ranks, res_ranks}, ntest, {'gt', 'det', 'det w/ spatial'})
saveas(h, 'result.png');