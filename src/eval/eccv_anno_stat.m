% eccv annotation statistics
% load('outputsungtfree', 'output');
outputs = {};
load('outputsungtguide', 'output');
outputs{1} = output;
load('outputsungtfree', 'output');
outputs{2} = output;
legendnames = {'GT-guided', 'GT-free'};
% output = [output_gtfree; output_gtguide];
stats = {};
for oo = 1:2
    output = outputs{oo};

    relationpath = '../data/relations-sunrgbd';
    textpath = '../text2relations/written_text-sunrgbd-all.txt';
    names = output.Var1;
    suffix  = '.jpg-relation.mat';
    num_objs = [];
    num_rels = [];
    rels = {};
    jpglist = {};
    objects = {};
    for i = 1:length(names)
        [~, name, ~]  = fileparts(names{i});
        jpglist{i} = [name '.jpg'];
        relationfile = fullfile(relationpath, [name suffix]);
        relation = load(relationfile);
        objects = [objects relation.nouns(1,:)];
        num_objs(i) = sum(cellfun(@(x)(str2num(x)), relation.nouns(2,:)));
        num_rels(i) = length(relation.rel);
        for j = 1:length(relation.rel)
            rels = [rels, relation.rel{j}{3}];
        end
    end

    ave_objs = mean(num_objs);
    ave_rels = mean(num_rels);
    fprintf(1, 'ave_objs = %f\n', ave_objs);
    fprintf(1, 'ave_rels = %f\n', ave_rels);

    unique_rels = unique(rels);
    cnt = zeros(1, length(unique_rels));
    for i = 1:length(rels)
        k = strcmp(unique_rels, rels{i});
        cnt(k) = cnt(k) + 1;
    end
    h = figure(oo);
    no_against = ~strcmp('against', unique_rels);
    index_front = strcmp('in_front_of', unique_rels);
    unique_rels{index_front} = 'in-front-of';
    index_front = strcmp('left', unique_rels);
    unique_rels{index_front} = 'on-left-of';
    index_front = strcmp('right', unique_rels);
    unique_rels{index_front} = 'on-right-of';
    unique_rels = unique_rels(no_against);
    cnt = cnt(no_against);
    stats{oo} = [];
    stats{oo}.rels = unique_rels;
    stats{oo}.cnt = cnt;
    [sorted_cnt, sorted_index] = sort(cnt);
    c = lines;
    h = bar(sorted_cnt, 'facecolor', c(6, :));
    ax = gca;
    ax.XTickLabel = unique_rels(sorted_index);
    ax.XTickLabelRotation = 45;
    xlim([0.5 length(cnt) + 0.5]);
    grid on;
    set(gca,'TickLabelInterpreter','none')
    xlabel('Spatial Relation');
    ylabel('Frequency');
    set(gca, 'fontsize', 15);
%     saveas(h, 'eccv-rel-stat.eps', 'ps2c');

    for i = 1:length(objects)
        k = strfind(objects{i}, '-');
        objects{i} = objects{i}(1:k(end)-1);
    end
    index = find(strcmp(objects, 'double-sofa'));
    for j = 1:length(index)
        objects{index(j)} = 'sofa';
    end
    index = find(strcmp(objects, 'triple-sofa'));
    for j = 1:length(index)
        objects{index(j)} = 'sofa';
    end
    index = find(strcmp(objects, 'long-table'));
    for j = 1:length(index)
        objects{index(j)} = 'sofa';
    end
    unique_objs = unique(objects);
    unique_objcnts = zeros(1, length(unique_objs));
    for j = 1:length(objects)
        index = strcmp(objects{j}, unique_objs);
        unique_objcnts(index) = unique_objcnts(index) + 1;
    end
    index = strcmp(unique_objs, 'wall');
    unique_objs = unique_objs(~index);
    unique_objcnts = unique_objcnts(~index);
    index = strcmp(unique_objs, 'right');
    unique_objs = unique_objs(~index);
    unique_objcnts = unique_objcnts(~index);

    stats{oo}.objs = unique_objs;
    stats{oo}.objcnts = unique_objcnts;
    
    textdata = importdata(textpath);
    assert(mod(size(textdata, 1), 2) == 0);
    textdata = reshape(textdata, 2, size(textdata, 1) / 2);
    N = size(textdata, 2);
    data = {};
    for i = 1:N
        if ~isempty(find(strcmp(textdata{1, i}, jpglist), 1))
            data = [data; {textdata{1, i}, textdata{2, i}}];
        end
    end

    numsent = [];
    numword = [];
    for i = 1:size(data, 1)
        s = data{i, 2};
        numsent(i) = length(strfind(s, '.'));
        numword(i) = length(strfind(s, ' ')) + 1;
    end

    fprintf(1, 'ave_word = %f\n', mean(numword));
    fprintf(1, 'ave_sent = %f\n', mean(numsent));
end
unique_rels = [stats{1}.rels, stats{2}.rels];
unique_rels = unique(unique_rels);
unique_cnts = zeros(length(unique_rels), 2);
for oo = 1:2
    rels = stats{oo}.rels;
    cnts = stats{oo}.cnt;
    for i = 1:length(rels)
        index = strcmp(rels{i}, unique_rels);
        unique_cnts(index, oo) = cnts(i);
    end
end
h = figure(3);
[sorted_cnt, sorted_index] = sort(sum(unique_cnts, 2), 'descend');
ntest = size(outputs{1}, 1) + size(outputs{2}, 1);
sorted_cnt = unique_cnts(sorted_index, :) / 50;
c = lines;
hb = bar(sorted_cnt, 'stacked');
hb(1).FaceColor = c(5, :);
hb(2).FaceColor = c(6, :);
ax = gca;
ax.XTickLabel = unique_rels(sorted_index);
ax.XTickLabelRotation = 45;
xlim([0.5 length(sorted_cnt) + 0.5]);
grid on;
set(gca,'TickLabelInterpreter','none')
xlabel('Spatial Relation');
ylabel('Frequency (Occurrences per Query)');
set(gca, 'fontsize', 15);
legend(legendnames);
saveas(h, 'eccv-rel-stat.eps', 'ps2c');

% plot obj cnt
unique_objs = [stats{1}.objs, stats{2}.objs];
unique_objs = unique(unique_objs);
unique_objcnts = zeros(length(unique_objs), 2);
for oo = 1:2
    objs = stats{oo}.objs;
    objcnts = stats{oo}.objcnts;
    for i = 1:length(objs)
        index = strcmp(objs{i}, unique_objs);
        unique_objcnts(index, oo) = objcnts(i);
    end
end
h = figure(4);
[sorted_cnt, sorted_index] = sort(sum(unique_objcnts, 2), 'descend');
ntest = size(outputs{1}, 1) + size(outputs{2}, 1);
sorted_cnt = unique_objcnts(sorted_index, :) / 50;
c = lines;
hb = bar(sorted_cnt, 'stacked');
hb(1).FaceColor = c(5, :);
hb(2).FaceColor = c(6, :);
ax = gca;
ax.XTick = 1:length(sorted_cnt);
ax.XTickLabel = unique_objs(sorted_index);
ax.XTickLabelRotation = 45;
xlim([0.5 length(sorted_cnt) + 0.5]);
grid on;
set(gca,'TickLabelInterpreter','none')
xlabel('Object Category');
ylabel('Frequency (Occurrences per Query)');
set(gca, 'fontsize', 15);
legend(legendnames);
saveas(h, 'eccv-obj-stat.eps', 'ps2c');