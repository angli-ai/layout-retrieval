function score = baseline_compare(input, gt)
score = 0;
for i = 1:length(input.classes)
    classname = input.classes{i};
    index = find(strcmp(classname, gt.classes));
    if isempty(index)
        score = score + input.numbers(i);
    else
        assert(length(index) == 1);
%         score = score + max(0, input.numbers(i) - gt.numbers(index));
        score = score + abs(input.numbers(i) - gt.numbers(index));
    end
end