% baseline eval

dataset = 'sunrgbd';
inputdir = fullfile('baseline-data', dataset);
resultdir = ['../cvpr17evaldata/output-' dataset '-5-det'];

resultlist = dir(fullfile(resultdir, '*.mat'));
resultlist = {resultlist(:).name};

% load ground truth
detection_dir = fullfile('detection-box', odataset);
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
det_counts_soft = {};
for i = 1:ntest
    gt_counts{i} = count_strings(gt.gtbbox_test{i}.classname);
    det_counts{i} = count_strings_thresh(detection.detection{i}, threshold);
    det_counts_soft{i} = count_strings_conf(detection.detection{i});
end

res_ranks_mean = [];
res_ranks_max = [];
gt_ranks = [];
det_ranks = [];
det_ranks_soft = [];
queries = {};

eps = 1e-9;

for id = 1:length(resultlist)
%     id = 17;
    fprintf(1, '%d/%d\n', id, length(resultlist));
    imagename = resultlist{id};
%     inputmat = fullfile(inputdir, imagename);
%     assert(length(inputmat) == 1);
%     inputmat = inputmat.name;
    inputmat = imagename;

    index = strfind(inputmat, '-');
    queryid = imagename;
    if isempty(index)
        continue;
        index = strfind(inputmat, '.mat');
        imageid = str2num(inputmat(1:index(end)-1));
        imagename = (inputmat(1:index(end)-1));
    else
%         continue;
%     imageid = inputmat(index(1)+1:index(2)-5);
%     imageid = str2num(imageid);
        jj = index(1);
        index = strfind(inputmat, '.mat');
        imagename = inputmat(1:index(end)-1);
        imageid = str2num(inputmat(jj+1:index(end)-1));
    end
    
    disp(imageid);
    
    if exist(fullfile(resultdir, inputmat), 'file')
        result = load(fullfile(resultdir, inputmat));
        score_res_mean = -mean(result.final_score, 2);
        score_res_max = -max(result.final_score, [], 2);
    else
        score_res = [];
        continue;
    end
    
    
    queries = [queries queryid];

    inputdata = load(fullfile(inputdir, [imagename '.jpg-relation.mat']));
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
    
    if ~isempty(score_res_mean)
        score = score_res_mean(imageid);
        rank = round((sum(score_res_mean < score - eps) + 1 + sum(score_res_mean < score + eps)) / 2);
%         [~, rank] = sort(score_res(A));
%         [~, rank] = sort(rank);
%         res_ranks = [res_ranks rank(B(imageid))];
        res_ranks_mean = [res_ranks_mean rank];
        
        score = score_res_max(imageid);
        rank = round((sum(score_res_max < score - eps) + 1 + sum(score_res_max < score + eps)) / 2);
        res_ranks_max = [res_ranks_max rank];
    end
end
h = figure(1);
tableres = plot_curves({gt_ranks, det_ranks, det_ranks_soft, res_ranks_mean, res_ranks_max}, ntest, {'gt', 'det', 'det soft', 'ours mean', 'ours max'});
output = table(queries', gt_ranks', det_ranks', det_ranks_soft', res_ranks_mean', res_ranks_max');
saveas(h, ['result.png']);