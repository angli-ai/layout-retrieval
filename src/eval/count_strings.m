function output = count_strings(inputs)
names = {};
counts = [];
for i = 1:length(inputs)
    index = find(strcmp(names, inputs{i}));
    assert(length(index) <= 1);
    if isempty(index)
        names = [names inputs{i}];
        counts = [counts 1];
    else
        counts(index) = counts(index) + 1;
    end
end
output = [];
output.classes = names;
output.numbers = counts;