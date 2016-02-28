% expand relation set according to the number of objects.
function new_relation = relation_preprocess(relation)
objectnames = relation.nouns(1, :);
objectcounts = cellfun(@str2num, relation.nouns(2, :));

new_relation = [];
new_relation.nouns = {};
new_relation.rel = {};

for i = 1:length(relation.rel)
    elem = relation.rel{i};
    firstnames = get_objectnames(elem{1}, objectnames, objectcounts);
    new_relation.nouns = [new_relation.nouns firstnames];
    
    for j = 1:length(firstnames)
        if strcmp(elem{2}, 'each-other')
            for k = j+1:length(firstnames)
                new_relation.rel = [new_relation.rel; {firstnames{j}, firstnames{k}, elem{3}}];
            end
        else
            secondnames = get_objectnames(elem{2}, objectnames, objectcounts);
            for k = 1:length(secondnames)
                new_relation.rel = [new_relation.rel; {firstnames{j}, secondnames{k}, elem{3}}];
            end
            new_relation.nouns = [new_relation.nouns secondnames];
        end
    end
end
new_relation.nouns = unique(get_rootname(new_relation.nouns));

% get regular object dimensions
new_relation = get_objectsizes(new_relation);