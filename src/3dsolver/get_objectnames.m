function namearray = get_objectnames(name, objectnames, objectcounts)
% return a cell array of object names according to the
% original object name and its count.
rootname = get_rootname(name);
index = find(strcmp(rootname, objectnames));
assert(~isempty(index), [name ' not found in objectnames']);
count = objectcounts(index);
assert(abs(count - fix(count)) < eps, ['object count ' num2str(count) ' should be integer']);
if count == 1
    namearray = {name};
else
    namearray = cell(1, count);
    for j = 1:count
        namearray{j} = append_objectname(name, int2str(j-1));
    end
end