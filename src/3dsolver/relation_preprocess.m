% expand relation set according to the number of objects.
function new_relation = relation_preprocess(relation)
objectnames = relation.nouns(1, :);
objectcounts = cellfun(@str2num, relation.nouns(2, :));

new_relation = [];
new_relation.nouns = {};
new_relation.rel = {};
new_relation.occ = {};
new_relation.wallobj = {};

for i = 1:length(relation.rel)
    elem = relation.rel{i};
    firstnames = get_objectnames(elem{1}, objectnames, objectcounts);
    new_relation.nouns = [new_relation.nouns firstnames];
    
    if strcmp(elem{3}, 'in-a-row') && isempty(elem{2})
        assert(length(firstnames) > 1);
        for j = 2:length(firstnames)
            new_relation.rel = [new_relation.rel; {firstnames{j-1}, firstnames{j}, elem{3}}];
            new_relation.rel = [new_relation.rel; {firstnames{j-1}, firstnames{j}, 'right'}];
        end
        continue;
    end
    
    if strcmp(elem{3}, 'occluded') && isempty(elem{2})
        new_relation.occ = [new_relation.occ firstnames];
        continue;
    end
    
    if strcmp(elem{3}, 'against') && strncmp(elem{2}, 'wall', 4)
        new_relation.wallobj = [new_relation.wallobj firstnames];
        continue;
    end
    
    for j = 1:length(firstnames)
        if strcmp(elem{2}, 'each-other')
            for k = j+1:length(firstnames)
                new_relation.rel = [new_relation.rel; {firstnames{j}, firstnames{k}, elem{3}}];
            end
        else
            secondnames = get_objectnames(elem{2}, objectnames, objectcounts);
            if length(secondnames) == 1
                secondnames = secondnames{1};
            end
            new_relation.rel = [new_relation.rel; {firstnames{j}, secondnames, elem{3}}];
            new_relation.nouns = [new_relation.nouns secondnames];
        end
    end
end
new_relation.nouns = unique(get_rootname(new_relation.nouns));
new_relation.occ = unique(new_relation.occ);

for i = 1:size(new_relation.rel, 1)
    if strncmp(new_relation.rel{i, 1}, 'pillow', 6) ...
            && strcmp(new_relation.rel{i, 3}, 'on')
        if strncmp(new_relation.rel{i, 2}, 'bed', 3) 
            rel = new_relation.rel(i, :);
            rel{2} = [rel{2} ':head'];
            rel{3} = 'attach';
            new_relation.rel = [new_relation.rel; rel];
        elseif strncmp(new_relation.rel{i, 2}, 'sofa', 4)
            rel = new_relation.rel(i, :);
            rel{2} = [rel{2} ':back'];
            rel{3} = 'attach';
            new_relation.rel = [new_relation.rel; rel];
        end
    end
end

% get regular object dimensions
new_relation = get_objectsizes(new_relation);