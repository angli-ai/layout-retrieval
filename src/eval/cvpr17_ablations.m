% cvpr 2017 ablations

% baseline eval

gtfree = true;
topK = [1 10 50 100 500 1000];

dataset = 'sunrgbd';
dataset = 'cvpr17sun-v1';
inputdir = fullfile('baseline-data', dataset);
baseline2 = load('../learn2d/gtrank-lr.mat');

params = [1, 5, 10];
object = 'layout';
datalist = '../cvpr17evaldata/filelist.txt';
resultlist = importdata(datalist);
resultname = {};
cnt = 0;
newparams = [];
for i = 1:length(params)
    switch object
        case 'layout'
            name = sprintf('../cvpr17evaldata/ablations-cvpr17sun-%d-5', params(i));
        case 'viewpoint'
            name = sprintf('../cvpr17evaldata/ablations-cvpr17sun-5-%d', params(i));
    end
    cnt = cnt + 1;
    newparams(cnt) = params(i);
    resultname{cnt} = name;
    for k = 2:5
        folder = [name '-v' num2str(k)];
        if exist(folder, 'dir')
            cnt = cnt + 1;
            newparams(cnt) = params(i);
            resultname{cnt} = folder;
        end
    end
end
params = newparams;
    
Nresults = length(resultname);
resultrank = cell(1, Nresults);

dataset = 'sunrgbd';
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

eps = 1e-9;

queries = {};
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
    jj = index(1);
    index = strfind(inputmat, '.mat');
    imagename = inputmat(1:index(end)-1);
    imageid = str2num(inputmat(jj+1:index(end)-1));
    
    for k = 1:Nresults
        if exist(fullfile(resultname{k}, inputmat), 'file')
            result = load(fullfile(resultname{k}, inputmat));
            scores = -max(result.final_score, [], 2);
            score = scores(imageid);
            rank = round((sum(scores < score - eps) + 1 + sum(scores < score + eps)) / 2);
            resultrank{k} = [resultrank{k} rank];
        else
            error([fullfile(resultname{k}, inputmat) ' does not exist']);
        end
    end
    
    queries{id} =  queryid;
end
method = {};
for i = 1:length(params)
    method{i} = num2str(params(i));
end
h = figure(1);
tableres = plot_curves(resultrank, ntest, method);
resultrank_cell = {};
medianrank = [];
for k = 1:Nresults
    resultrank_cell{k} = resultrank{k}';
    medianrank(k) = median(resultrank{k});
end
output = table(queries', resultrank_cell{:});
% output = table(queries', resultrank{1}', resultrank{2}', resultrank{3}');

rowname = {};
proposed_res = zeros(Nresults, length(topK));
for k = 1:length(topK)
    rowname{k} = num2str(topK(k), 'Top %d');
    proposed_res(:, k) = tableres(1:Nresults, topK(k));
end
proposed = {};
for k = 1:Nresults
    proposed{k} = proposed_res(k, :)';
end
det_anno_table = table(rowname', proposed{:});

%det_anno_table = table(rowname', proposed_res(1, :)', proposed_res(2,:)', proposed_res(3,:)');
print_table_tex(det_anno_table);
lineset = {};
for i = 1:length(params)
    lineset{i} = '-';
end
tableres = eccv_plot_curves(...
    resultrank, ...
    ntest, ...
    method, lineset);
saveas(h, 'result.png');
%%

plotmethod = 'medianrankpercentile';
plotmethod = 'medianrank';
% plotmethod = 'auc500';
topkk =10;
auc500 = sum(tableres(:, 1:topkk), 2)/topkk;
meany = tableres(:, 1:topkk);
uniqueparams = unique(params);
h = figure(3);
x = 1:topkk;
X = repmat(x, length(uniqueparams), 1);
Y = [];
U = [];
L = [];
for i = 1:length(uniqueparams)
    idx = find(uniqueparams(i) == params);
    y = tableres(idx, 1:topkk);
    meany = mean(y, 1);
    uperr = max(y, [], 1) - meany;
    loerr = meany - min(y, [], 1);
    Y = [Y; meany(x)];
    U = [U; uperr(x)];
    L = [L; loerr(x)];
end
% plot(X', Y');
errorbar(X', Y', U', L', '-s');
h = figure(2);
switch plotmethod
    case 'medianrank'
        [x, y, py, ny] = geterrors(params, medianrank);
        ylabeltext = 'Median rank';
    case 'medianrankpercentile'
        [x, y, py, ny] = geterrors(params, 100-medianrank/ntest*100);
        ylabeltext = 'Median percentile rank';
    case 'auc500'
        [x, y, py, ny] = geterrors(params, auc500);
        ylabeltext = 'Area Under the Curve @ 500';
end

switch object
    case 'viewpoint' 
        xlabeltext = '# Viewpoints per 3D layout';
    case 'layout'
        xlabeltext = '# 3D layouts per query';
end
    
errorbar(x, y, ny, py, '-s', 'linewidth', 2, 'MarkerSize', 10, 'MarkerFaceColor', [0, 0.5, 1]);
xlabel(xlabeltext);
% ylabel('Top500 AUC');
ylabel(ylabeltext);
% ylim([96.5 98.5]);
ylim([95 175]);
set(gca, 'fontsize', 25);
grid on;
xlim([0 max(params)+1]);
saveas(h, [object '-' plotmethod '.eps'], 'ps2c');