% eccv annotation statistics
% load('outputsungtfree', 'output');
load('outputsungtguide', 'output');

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
bar(cnt);

unique_objs = unique(objects);
for i = 1:length(unique_objs)
    k = strfind(unique_objs{i}, '-');
    unique_objs{i} = unique_objs{i}(1:k(end)-1);
end
unique_objs = unique(unique_objs);

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