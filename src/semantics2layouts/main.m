relation_path = '../relations';
output_path = '../arrangements';

if ~exist(output_path, 'dir')
    mkdir(output_path);
end

num_layouts = 4;

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
    [data, layout_bounds] = semantics2layouts(rel, num_layouts);
    save(fullfile(output_path, filename), 'data');
end