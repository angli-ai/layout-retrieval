% generate baseline input data
inputdir = '/Users/ang/projects/layout3d/layout-retrieval/src/3dsolver/testdata-2';
outputdir = 'baseline-inputs';

if ~exist(outputdir, 'dir')
    mkdir(outputdir);
end

matfiles = dir(fullfile(inputdir, '*.mat'));
matfiles = {matfiles(:).name};
for i = 1:length(matfiles)
    classes = {};
    numbers = [];
    data = load(fullfile(inputdir, matfiles{i}));
    nouns = data.nouns;
    for j = 1:size(nouns, 2)
        index = strfind(nouns{1, j}, '-');
        noun = nouns{1, j}(1:index(end)-1);
        index = find(strcmp(noun, classes));
        count = str2num(nouns{2, j});
        if isempty(index)
            classes = [classes, noun];
            numbers = [numbers, count];
        else
            assert(length(index) == 1);
            numbers(index) = numbers(index) + count;
        end
    end
    disp(classes);
    disp(numbers);
    save(fullfile(outputdir, matfiles{i}), 'classes', 'numbers');
end