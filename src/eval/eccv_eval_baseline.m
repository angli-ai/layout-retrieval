% baseline eval

gtfree = false;
topK = [1 10 50 100 500 1000];

dataset = 'sunrgbd';
inputdir = fullfile('baseline-data', dataset);

resultname = {'gt', '../eval-data/output-sunrgbd-1-5-gt'; ...
    'det_hard', '../eval-data/output-sunrgbd-1-5-det0.5'; ...
    'det_soft', '../eval-data/output-sunrgbd-1-5-det'};
% resultname = {'gt', '../eval-data/output-3dgp-1-5-gt'; ...
%     'det_hard', '../eval-data/output-3dgp-1-5-det-inf'};
Nresults = size(resultname, 1);
resultrank = cell(1, Nresults);

resultlist = dir(fullfile(resultname{1,2}, '*.mat'));
resultlist = {resultlist(:).name};

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

if strcmp(dataset, '3dgp')
    for i = 1:ntest
    n = size(detection.detection{i}, 1);
    detection.detection{i}.bg_conf = zeros(n, 1);
    end
end
gt_counts = {};
det_counts = {};
det_counts_soft = {};
for i = 1:ntest
    gt_counts{i} = count_strings(gt.gtbbox_test{i}.classname);
    det_counts{i} = count_strings_thresh(detection.detection{i}, threshold);
    det_counts_soft{i} = count_strings_conf(detection.detection{i});
end

gt_ranks = [];
det_ranks = [];
det_ranks_soft = [];
queries = {};

eps = 1e-9;

for id = 1:length(resultlist)
%     id = 17;
    fprintf(1, '%d/%d\n', id, length(resultlist));
    imagename = resultlist{id};
%     assert(strcmp(gtlist{id}, detlist{id}));
%     inputmat = fullfile(inputdir, imagename);
%     assert(length(inputmat) == 1);
%     inputmat = inputmat.name;
    inputmat = imagename;

    index = strfind(inputmat, '-');
    queryid = imagename;
    if isempty(index)
        if gtfree
            continue;
        end
        index = strfind(inputmat, '.mat');
        imageid = str2num(inputmat(1:index(end)-1));
        imagename = (inputmat(1:index(end)-1));
    else
%     imageid = inputmat(index(1)+1:index(2)-5);
%     imageid = str2num(imageid);
        if ~gtfree
            continue;
        end
        jj = index(1);
        index = strfind(inputmat, '.mat');
        imagename = inputmat(1:index(end)-1);
        imageid = str2num(inputmat(jj+1:index(end)-1));
    end
    
    disp(imageid);
    
    for k = 1:Nresults
        if exist(fullfile(resultname{k, 2}, inputmat), 'file')
            result = load(fullfile(resultname{k, 2}, inputmat));
            scores = -max(result.final_score, [], 2);
            score = scores(imageid);
            rank = round((sum(scores < score - eps) + 1 + sum(scores < score + eps)) / 2);
            resultrank{k} = [resultrank{k} rank];
        else
            error([fullfile(resultname{k, 2}, inputmat) ' does not exist']);
        end
    end
    
    queries = [queries queryid];

    inputdata = load(fullfile(inputdir, [imagename '.jpg-relation.mat']));
    for i = 1:length(inputdata)
        inputdata.classes{i} = fixclassname(inputdata.classes{i});
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
    end
h = figure(1);
tableres = plot_curves([{gt_ranks, det_ranks, det_ranks_soft} resultrank], ntest, {'gt', 'det', 'det soft', resultname{:, 1}});
output = table(queries', gt_ranks', det_ranks', det_ranks_soft', resultrank{1}', resultrank{2}', resultrank{3}');

rowname = {};
gt_res = [];
det_res = [];
det_soft_res = [];
proposed_res = zeros(Nresults, length(topK));
for k = 1:length(topK)
    rowname{k} = num2str(topK(k), 'Top %d');
    gt_res(k) = tableres(1, topK(k));
    det_res(k) = tableres(2, topK(k));
    det_soft_res(k) = tableres(3, topK(k));
    proposed_res(:, k) = tableres(4:3+Nresults, topK(k));
end
det_anno_table = table(rowname', gt_res', proposed_res(1, :)', det_res', proposed_res(2,:)', proposed_res(3,:)');
print_table_tex(det_anno_table);
tableres = eccv_plot_curves(...
    {gt_ranks, det_ranks, resultrank{1}, resultrank{2}, resultrank{3}}, ...
    ntest, ...
    {'gt', 'det', 'ours gt max', 'ours det hard max', 'ours det soft max'}, ...
    {'--', '--', '-', '-', '-'});
saveas(h, 'result.png');