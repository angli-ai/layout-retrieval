rootpath = '../../data';
relation_path = fullfile(rootpath, 'relations');
output_path = fullfile(rootpath, 'arrangements');

if ~exist(output_path, 'dir')
    mkdir(output_path);
end

num_layouts = 5;

matfiles = dir(fullfile(relation_path, '*.mat'));
for i = 1:length(matfiles)
    filename = matfiles(i).name;
    disp(filename);
    if exist(fullfile(output_path, filename), 'file')
        continue
    end
    load(fullfile(relation_path, filename));
    if isempty(rel)
        continue
    end
    outputfile = fullfile(output_path, filename);
    if exist(outputfile, 'file')
        load(outputfile, 'layout_bounds');
        [data, layout_bounds, tot] = semantics2layouts(rel, num_layouts, layout_bounds);
    else
        [data, layout_bounds, tot] = semantics2layouts(rel, num_layouts);
    end
    save(outputfile, 'data', 'layout_bounds', 'tot');
end