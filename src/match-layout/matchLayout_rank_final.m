% match textual layout to database
function matchLayout_rank_final
close all;
clear;

if matlabpool('size')>0    
    matlabpool close;
end
if matlabpool('size') == 0 % checking to see if my pool is already open
    matlabpool('6')
end

% detection results of image database
[database_detections,database_imgnames,IDmap_150_testset] = database_testset();

ims = cell(length(database_imgnames),1);
for i=1:length(database_imgnames)
    ims{i} = imread(['../../data/imgs/' database_imgnames{i}]);
end


% query list
relationList = dir('../../3dgp/data-v2/arrangements/');

if ~exist('../../data/imgs/')
    disp('3dgp raw images needed! Please make a symbol link at ../../data/imgs/ -> <3DGP>/cvpr13data/');
    return
end

relation_allscore = cell(length(relationList),1);
bestlayout_all = cell(length(relationList),1);
bestscore_all = cell(length(relationList),1);

if ~exist('../../results/')
    mkdir('../../results');
end

% for each query input
parfor r=3:length(relationList)
tic;
    disp(['relation ' num2str(r-2) '/' num2str(length(relationList)-2)]);
    filename = relationList(r).name;
    d = load(['../../3dgp/data-v2/arrangements/' filename]);
    data = d.data;
    % groundtruth image index for input textual layout
    imgidx = str2num(filename(1:3));
   
    % skip if not in test set
    if ~isKey(IDmap_150_testset, imgidx)
        continue;
    end
 
    testset_idx = IDmap_150_testset(imgidx);
    imgidx = -1;
    

    % init proposed method best rank for groundtruth image
    bestrank = length(database_detections);
    % init baseline method best rank (not changing for different layout) for
    % groundtruth image
    bestrank_base = length(database_detections);



    % layout loop
    if ~isempty(data.layouts)
        % scores of all database images and all layout
        allscores = zeros(length(data.layouts)*length(data.layouts(1).layout2d),length(database_detections));
        allscores_counter = 1;
        % scores of best ranked groundtruth image
        bestscore = zeros(length(database_detections),1);
        % cooresponding layout input
        bestlayout = zeros(6,4);
        % for each layout
        for k=1:length(data.layouts)
            % for each 3d/2d sample
            for m=1:length(data.layouts(k).layout2d)
                % all possible 6x4 layout for given 2d projections
                textLayout_all = getTextLayout(data.layouts(k).layout2d(m).objects);
                
                % score to generate rank list
                scores = zeros(length(database_detections),1);
                scores_base = zeros(length(database_detections),1);
                layout_list = zeros(length(database_detections));
                
                % for each image in the database
                for i=1:length(database_detections)
                    %disp(sprintf('data.lyaouts: %d, layout2d: %d, database: %d', k, m, i));
                    %im = imread(['../../data/imgs/' database_imgnames{i}]);
                    
                    % read detection boxes of this database image
                    % image layout: [upperleft xy, lowerright xy]
                    layout = detection2layout(database_detections{i});

                    % convert image box to canonical space (y axis from large to small)
                    layout(:,2) = size(ims{i},1)-layout(:,2);
                    layout(:,4) = size(ims{i},1)-layout(:,4);
                    

                    
                    
                    scores_l = zeros(1,length(textLayout_all));
                    for t = 1:length(textLayout_all)
                        % calculate matching score
                        scores_l(t) = calculateScore(textLayout_all{t},layout);
                    end
                    
                    % find best score for all possible 6x4 layout
                    [scores(i),maxidx] = max(scores_l);
                    layout_list(i) = maxidx;
                    % for baseline, layout doesn't matter, and only need to
                    % calculate once
                    if k==1
                        scores_base(i) = calculateScore_nolayout(textLayout_all{1},layout);
                    end
                end

                [~,idx] = sort(scores,'descend');
                c_rank = find(idx==testset_idx);
                c_layout = textLayout_all{layout_list(testset_idx)};
                if c_rank < bestrank
                    bestrank = c_rank;
                    bestscore = scores;
                    bestlayout = c_layout;
                end

                if k==1
                    [~,idx_base] = sort(scores_base,'descend');
                    c_rank_base = find(idx_base==testset_idx);
                    if c_rank_base < bestrank_base
                        bestrank_base = c_rank_base;
                    end
                end
                
                allscores(allscores_counter,:) = scores;
                allscores_counter = allscores_counter+1;

            end
        end
        
        meanscore = mean(allscores);
        [~,idx] = sort(meanscore,'descend');
        meanscore_rank = find(idx==testset_idx);

        maxscore = max(allscores);
        [~,idx] = sort(maxscore,'descend');
        maxscore_rank = find(idx==testset_idx);

        disp(['relation ' num2str(r-2) ', mean rank: ' num2str(meanscore_rank) ', maxscore rank: ' num2str(maxscore_rank) ', bestrank: ' num2str(bestrank) ', baseline rank: ' num2str(bestrank_base)])

        % parfor cannot show image
        % showTop6(bestscore,imlist,r,bestlayout);
        bestlayout_all{r-2} = bestlayout;
        bestscore_all{r-2} = bestscore;


        relation_allscore{r-2} = allscores;

    end


toc;
end

for r=3:length(relationList)
    if ~isempty(bestscore_all{r-2})
        showTop6(bestscore_all{r-2},database_imgnames,r-2,bestlayout_all{r-2});
    end
end

save('../../results/relation_allscore.mat','relation_allscore','-v7.3');

end

%% Helper functions

% show top 6 retrieved images
function showTop6(scores,database_imgnames,r,bestlayout)
[~,idx] = sort(scores,'descend');

figure,
for i=1:6
    im =imread(['../../data/imgs/' database_imgnames{idx(i)}]);
    %load(['./data/' imlist(idx(i)).name '-layout.mat']);
    
    subplot(2,3,i),imshow(im)
    %for l=1:size(layout,1)
        %if layout(l,1)>10e-4
        %rectangle('EdgeColor',[1 0 0],'Position',[layout(l,1),layout(l,2),layout(l,3)-layout(l,1)+1,layout(l,4)-layout(l,2)+1]);
        %end
    %end
    disp(sprintf('Top im %d, %s, testset ID %d', i, database_imgnames{idx(i)}, idx(i)));
    imwrite(im,['../../results/top6-' num2str(r) '-' num2str(i) '.png']);
end

h = plotbox(bestlayout);
print(h,['../../results/textLayout-' num2str(r)],'-depsc2');

end

% function to plot layout boxes
function h = plotbox(box)

nameset = {'bed','chair','dining-table','side-table','sofa','table'};

h = figure;hold on;
for i=1:size(box,1)
    if box(i,1)~=-Inf && abs(box(i,1))>10^-5
        plot([box(i,1),box(i,3)],[box(i,2),box(i,4)],'r*');
        
        plot([box(i,1),box(i,3)],[box(i,2),box(i,2)],'b');
        plot([box(i,3),box(i,3)],[box(i,2),box(i,4)],'b');
        plot([box(i,3),box(i,1)],[box(i,4),box(i,4)],'b');
        plot([box(i,1),box(i,1)],[box(i,4),box(i,2)],'b');
        
        furnitureName = nameset{i};
        text((box(i,1)+box(i,3))/2,(box(i,2)+box(i,4))/2,furnitureName);
    end    
end
end


% read textual layout
function layout = getTextLayout(objects)
allobjects = cell(6,1);
for o=1:length(objects)
%   names = {'bed','chair','diningtable','sidetable','sofa','table'};
    c = strsplit(objects(o).name,'-');
    switch c{1}
        case 'bed'
            f = 1;
        case 'chair'
            f = 2;
        case 'dining'
            f = 3;
        case 'dinning'
            f = 3;
        case 'side'
            f=4;
        case 'sofa'
            f = 5;
        case 'table'
            f = 6;
    end
    allobjects{f} = 100*[allobjects{f};[objects(o).xmin,objects(o).ymax,objects(o).xmax,objects(o).ymin]];
end

% get all combinations
L = setprod(1:size(allobjects{1},1)+1,1:size(allobjects{2},1)+1,1:size(allobjects{3},1)+1,...
    1:size(allobjects{4},1)+1,1:size(allobjects{5},1)+1,1:size(allobjects{6},1)+1);

count = 0;
% for each combination
for l=1:size(L,1)
    flag = 0;
    clayout = -Inf*ones(6,4);
    % remove single furniture case
    if length(find(L(l,:)==1)) < 5
        flag = 1;
    end
    % for each furniture
    for o=1:size(L,2)
        if L(l,o)>1
            clayout(o,:) = allobjects{o}(L(l,o)-1,:);
        end
    end
    if flag
        count = count+1;
        layout{count} = clayout;
    end
end
end

% calculate matching score for textual layout X and detection layout Y
% baseline matching
function score = calculateScore_nolayout(X,Y)
score = 0;
% only match valid furnitures
l = find((X(:,1)~=-Inf & Y(:,1)>0)>0);

if ~isempty(l)
    Y = Y(l,:);
    score = sum((logsig(Y(:,end))));
end
end

% calculate matching score for textual layout X and detection layout Y
% proposed matching, last column of Y contains detection score
function score = calculateScore(X,Y)
score = 0;
% only match valid furnitures
l = find((X(:,1)~=-Inf & Y(:,1)>0)>0);

X = X(l,:);
Y = Y(l,:);

% first get furniture centers
centerX = [(X(:,1)+X(:,3))/2,(X(:,2)+X(:,4))/2];
centerY = [(Y(:,1)+Y(:,3))/2,(Y(:,2)+Y(:,4))/2];

if ~isempty(l)
    % each layout center
    refVecX = mean(centerX,1);
    refVecY = mean(centerY,1);

    % remove translation
    centerX = centerX - repmat(refVecX,size(X,1),1);
    centerY = centerY - repmat(refVecY,size(Y,1),1);

    % find best scale
    if size(centerX,1)==1
        s = (Y(1)-refVecY(1))/(X(1)-refVecX(1));
    else
        if size(centerX,1)==2
            s = centerY(1,1)/centerX(1,1);
        else
            s = findBestScale(centerX,centerY);
        end
    end

    % transform all furnitures
    Y(:,1:2) = (Y(:,1:2)-repmat(refVecY,size(Y,1),1))/s;
    Y(:,3:4) = (Y(:,3:4)-repmat(refVecY,size(Y,1),1))/s;
    X(:,1:2) = X(:,1:2)-repmat(refVecX,size(X,1),1);
    X(:,3:4) = X(:,3:4)-repmat(refVecX,size(X,1),1);
    
    % now calculate area overlap rate
    area = zeros(1,size(Y,1));
    for i=1:size(Y,1)
        %convert to image plane convention
        minx = abs(min(min([X(:,1),X(:,3),Y(:,1),Y(:,3)]))-1);
        maxy = max(max([X(:,2),X(:,4),Y(:,2),Y(:,4)]))+1;
        cX = X(i,1:4);
        cY = Y(i,1:4);
        cX(2) = maxy-cX(2);
        cX(4) = maxy-cX(4);
        cY(2) = maxy-cY(2);
        cY(4) = maxy-cY(4);
        cX(1) = cX(1)+minx;
        cX(3) = cX(3)+minx;
        cY(1) = cY(1)+minx;
        cY(3) = cY(3)+minx;
        area(i) = calculateOverlapRate(cX,cY);
    end

    score = area*logsig(Y(:,end));
end


end

%find best scale
%X,Y should be nx2 matrix
function s = findBestScale(X,Y)
s = X'*X\(X'*Y);

s = s(1,1);
end
