function [output, layout_bounds, tot] = semantics2layouts(semantics, num_layouts, varargin)

if nargin < 2
	semantics = {...
        {'bed-1', 'table-1', 'left'}, ...
        {'bed-1', 'table-2', 'right'}, ...
        {'side-table-1', 'table-2', 'front'}, ...
        {'sofa-1', 'table-1', 'near'}};
    semantics = {...
        {'bed-0', 'side-table-0', 'near'}, ...
        {'bed-0', 'side-table-1', 'near'}, ...
        {'sofa-0', 'bed-0', 'front'}};
    num_layouts = 4;
end

model = Model();

[objs, obj2id] = unique_objects_from_semantics(semantics);

Nobjs = length(objs);

for i = 1:length(semantics)
    semantic = semantics{i};
    obj_i = obj2id(semantic{1});
    obj_j = obj2id(semantic{2});
    semantics{i}{1} = obj_i;
    semantics{i}{2} = obj_j;
    semantics{i}{4} = 1;
end

boundmap = build_bound_matrix(Nobjs, semantics);

if nargin < 3
    [layout_bounds, tot] = solve_by_interval_analysis(Nobjs, semantics, boundmap, model);
else
    layout_bounds = varargin{1};
end

% layouts = random_by_interval_analysis(Nobjs, semantics);

layouts = zeros(Nobjs*2, 4);

if ~isempty(layout_bounds)
    cnt = 0;
    while cnt < num_layouts
        for i = randperm(length(layout_bounds))
            cnt = cnt + 1;
            layouts(:, cnt) = random_btw(layout_bounds{i}(:, 1), layout_bounds{i}(:, 2));
            if cnt == num_layouts
                break;
            end
        end
    end
else
    layouts = {};
end

disp(layouts);
% output = [];
% output.layout_bounds = layout_bounds;
% output.layouts = layouts;
% output.objs = objs;

% output = [];

output = generate_image_proj(layouts, objs);


% save(outputfile, 'layout_bounds', 'layouts', 'objs');
% layouts = solve_by_LP(Nobjs, semantics, model, num_layouts)

% function layouts = solve_by_bruteforce(semantics, obj2id)


function res = random_btw(lb, ub)
N = size(lb, 1);
res = rand(N, 1) .* (ub - lb) + lb;

% deprecated
function layouts = solve_by_LP(Nobjs, semantics, model, num_layouts)
% LP dim. = 2*Nobjs + 1
A = [];

for i = 1:length(semantics)
    semantic = semantics{i};
%     obj_i = obj2id(semantic{1});
%     obj_j = obj2id(semantic{2});
    obj_i = semantic{1};
    obj_j = semantic{2};
    rows = model.get_coeffs_from_rel(Nobjs, obj_i, obj_j, semantic{3});
    A = cat(1, A, rows);
end

layouts = sample_feasible_sols(A, model.room_size(1:2), num_layouts);


function [objs, obj2id] = unique_objects_from_semantics(semantics)
objs = {};
for i = 1:length(semantics)
    objs = [objs semantics{i}{1} semantics{i}{2}];
end
objs = unique(objs);
Nobjs = length(objs);
obj2id = containers.Map(objs, 1:length(objs));
