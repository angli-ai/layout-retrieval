function output = count_strings_conf(input)
index = input.bg_conf < input.conf;
input = input(index, :);
inputs = input.classname;
conf = input.conf;

names = {};
counts = [];
for i = 1:length(inputs)
    index = find(strcmp(names, inputs{i}));
    assert(length(index) <= 1);
    if isempty(index)
        names = [names inputs{i}];
        counts = [counts conf(i)];
    else
        counts(index) = counts(index) + conf(i);
    end
end
output = [];
output.classes = names;
output.numbers = counts;