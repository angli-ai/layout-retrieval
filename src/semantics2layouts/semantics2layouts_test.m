function semantics2layouts_test

map_objs = containers.Map( ...
    {'bed', 'closet', 'table', 'lamp'}, ...
    {1, 2, 3, 4});

room.size = [10 10 5];

rels = {'near', 'left', 'right', 'front', 'behind', 'above', 'below', 'on'};
map_rels = containers.Map(rels, 1:length(rels));

data = {{'bed-1', 'table-1', 'left'}, ...
    {'bed-1', 'closet-1', 'right'}, ...
    {'closet-1', 'closet-2', 'front'}, ...
    {'lamp-1', 'table-1', 'near'}};

objs = {};
for i = 1:length(data)
    objs = [objs data{i}{1} data{i}{2}];
end
objs = unique(objs);
Nobjs = length(objs);
id_objs = containers.Map(objs, 1:length(objs));
enc = semantics2index(data, id_objs, map_rels);
layouts = semantics2layouts(Nobjs, enc, 10);
disp(enc);
disp(layouts);

function enc = semantics2index(data, id_objs, map_rels)
N = length(data);

iObj1 = []; iObj2 = []; iRel = [];
for i = 1:N
    obj1 = data{i}{1};
    obj2 = data{i}{2};
    relation = data{i}{3};
    iObj1(i) = index_object_id(obj1, id_objs);
    iObj2(i) = index_object_id(obj2, id_objs);
    iRel(i) = index_relation(relation, map_rels);
end
enc = struct('N', N, 'obj1', iObj1, 'obj2', iObj2, 'rel', iRel);

function idx = index_object_id(obj, id_objs)
idx = id_objs(obj);

function idx = index_object(obj, objects)
j = strfind(obj, '-');
objname = obj(1:j-1);
idx = objects(objname);

function idx = index_relation(rel, map_rel)
idx = map_rel(rel);