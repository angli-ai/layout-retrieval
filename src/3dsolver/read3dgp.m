function read3dgp
f = fopen('/Users/ang/projects/layout3d/layout-retrieval/src/text2relations/text-cvpr173dgp.txt', 'r');
str = fgets(f);
currentid = '';
output = [];
while ischar(str)
    id = str2num(str);
    if ~isempty(id)
        currentid = id;
    end
    idx = strfind(str, '.jpg');
    if ~isempty(idx)
        outcell = {str, currentid};
        output = [output; outcell];
    end
    str = fgets(f);
end
fclose(f);

folder = '../cvpr17evaldata/output-cvpr173dgp-v1';
imagelist = dir(folder);
imagelist = {imagelist(:).name};
tot = 0;
gtidx = {};
querycnt = [];
for i = 1:length(imagelist)
    if strcmp(imagelist{i}, '.') || strcmp(imagelist{i}, '..')
        continue
    end
    idx = strfind(imagelist{i}, '.mat');
    id = imagelist{i}(1:idx-1);
    id = str2num(id);
    idx = find([output{:, 2}] == id);
    gtidx{id} = idx;
    querycnt(id) = length(idx);
    tot = tot + length(idx);
end
gtidx{57} = [];
gtidx{50} = [];

baseline2d_dpm = load('../learn2d/gtrank-lr-3dgp.mat');
baseline2d_gt = load('../learn2d/gtrank-lr-3dgp-gt.mat');
baselinec = load('../eval/scores-baselinec-3dgp.mat');
baselinec_gt = baselinec.scores_gt;
baselinec_dpm = baselinec.scores_det;

evalpath = {};
for i = 1:10
    epath = sprintf('../cvpr17evaldata/output-cvpr173dgp-v%d-det', i);
    if ~exist(epath, 'dir')
        break
    end
    evalpath{i} = epath;
end
filelist = dir(fullfile(evalpath{1}, '*.mat'));
filelist = {filelist(:).name};
rank = [];
queryrank = [];
myscores = {};
for j = 1:length(evalpath)
    myscores{j} = [];
end
mygtidx = {};
b2scores = [];
gt_b2scores = [];
gt_cscores = [];
cscores = [];

for i = 1:length(filelist)
    idx = strfind(filelist{i}, '.mat');
    id = str2num(filelist{i}(1:idx-1));
    if isempty(gtidx{id})
        continue
    end
    for j = 1:length(evalpath)
        data = load(fullfile(evalpath{j}, filelist{i}));
        scores = -max(data.final_score, [], 2);
        myscores{j} = [myscores{j}; scores'];
    end
    b2scores = [b2scores; -baseline2d_dpm.scores{id}];
    cscores = [cscores; baselinec_dpm{id}];
    gt_cscores = [gt_cscores; baselinec_gt{id}];
    gt_b2scores = [gt_b2scores; -baseline2d_gt.scores{id}];
    mygtidx = [mygtidx gtidx{id}];
end

rank = [];
curve = [];
for j = 1:length(evalpath)
[myrank, mycurve, N, Nquery] = get_result(myscores{j}, mygtidx);
rank = [rank; myrank];
curve = [curve; mycurve'];
end
rankL = min(rank, [], 1);
rankU = max(rank, [], 1);
rank = mean(rank, 1);
curveL = min(curve, [], 1);
curveU = max(curve, [], 1);
curve = mean(curve, 1);
[rankb2, curveb2] = get_result(b2scores, mygtidx);
[rankgtb2, curvegtb2] = get_result(gt_b2scores, mygtidx);
[rankgtc, curvegtc] = get_result(gt_cscores, mygtidx);
for i = 1:length(gtidx)
    if length(gtidx{i}) == 1
        fprintf(1, '%d %d %d %d\n', gtidx{i}, rank(gtidx{i}), rankb2(gtidx{i}), rankgtc(gtidx{i}));
    end
end
[rankc, curvec] = get_result(cscores, mygtidx);
curverand = [];
for i = 1:100
[~, curverandi] = get_result(rand(size(myscores{1})), mygtidx);
curverand = [curverand; curverandi'];
end
curverand = mean(curverand);
plot(1:N, curve, 1:N, curveb2, 1:N, curverand, 1:N, curvegtb2, 1:N, curvec, 1:N, curvegtc);
legend('ours', 'baseline-2D', 'Random', 'baseline-2D gt', 'baseline-C', 'baseline-C gt');

fprintf(1, 'Our: %.3f, %.3f, %.3f\n', curve(1), curve(10), curve(25));
fprintf(1, 'Our: %.3f, %.3f, %.3f\n', curveL(1), curveL(10), curveL(25));
fprintf(1, 'Our: %.3f, %.3f, %.3f\n', curveU(1), curveU(10), curveU(25));
fprintf(1, '2  : %.3f, %.3f, %.3f\n', curveb2(1), curveb2(10), curveb2(25));
fprintf(1, '2GT: %.3f, %.3f, %.3f\n', curvegtb2(1), curvegtb2(10), curvegtb2(25));
fprintf(1, 'RND: %.3f, %.3f, %.3f\n', curverand(1), curverand(10), curverand(25));
fprintf(1, 'C  : %.3f, %.3f, %.3f\n', curvec(1), curvec(10), curvec(25));
fprintf(1, 'CGT: %.3f, %.3f, %.3f\n', curvegtc(1), curvegtc(10), curvegtc(25));



function [rank, curve, N, Nquery] = get_result(myscores, gtidx)
rank = [];
for i = 1:length(gtidx)
    scores = myscores(i,:);
    gtindex = gtidx{i};
    minrank = inf;
    for j = 1:length(gtindex)
        score = scores(gtindex(j));
        [~, idx] = sort(scores);
        [~, myrank] = sort(idx);
        myrank = myrank(gtindex(j));
%         myrank = round((sum(scores < score - eps) + 1 + sum(scores < score + eps)) / 2);
%         myrank = sum(scores < score - eps) + 1;
        rank(gtindex(j)) = myrank;
        if minrank > myrank
            minrank = myrank;
        end
    end
    queryrank(i) = minrank;
end
rank(rank==0)=inf;
N = size(myscores, 2);
Nquery = length(queryrank);
curve = zeros(N, 1);
for i = 1:length(queryrank)
    idx = queryrank(i):N;
    curve(idx) = curve(idx) + 1;
end
curve = curve / Nquery;