function models = get_object_models()
% each object model is a cell of sub-objects
% and each sub-object is represented as
% 1. sub-object name
% 2. a matrix: corresponding to (x, y, z, lx, ly, lz)
% where dx, dy, dz is the relative location of main object
% and lx, ly, lz is the size of the object
% assume each sub-object is well represented by a cuboid.
% assume x-z is the main surface and y is the object direction.

models = [];
models.objects = {};
models.objindex = {};
models.subobjs = {};
models.cuboids = {};
models.cuboids_mat = [];
w = 0.01;

o4 = zeros(4, 1);
chair = [];
chair.back = {'chair:back', @(lx,ly,lz,hz)[o4,o4,lz,o4+w,ly,hz-lz]'};
chair.leg0 = {'chair:leg0', @(lx,ly,lz,hz)[o4,o4,o4,o4+w,o4+w,lz]'};
chair.leg1 = {'chair:leg1', @(lx,ly,lz,hz)[o4,ly-w,o4,o4+w,o4+w,lz]'};
chair.leg2 = {'chair:leg2', @(lx,ly,lz,hz)[lx-w,o4,o4,o4+w,o4+w,lz]'};
chair.leg3 = {'chair:leg3', @(lx,ly,lz,hz)[lx-w,ly-w,o4,o4+w,o4+w,lz]'};
chair.seat = {'chair:seat', @(lx,ly,lz,hz)[o4,o4,lz-w,lx+w,ly+w,o4+w]'};
models = add_models(models, 'chair', chair);

pianobench = [];
pianobench.leg0 = {'piano_bench:leg0', @(lx,ly,lz,hz)[o4,o4,o4,o4+w,o4+w,lz]'};
pianobench.leg1 = {'piano_bench:leg1', @(lx,ly,lz,hz)[o4,ly-w,o4,o4+w,o4+w,lz]'};
pianobench.leg2 = {'piano_bench:leg2', @(lx,ly,lz,hz)[lx-w,o4,o4,o4+w,o4+w,lz]'};
pianobench.leg3 = {'piano_bench:leg3', @(lx,ly,lz,hz)[lx-w,ly-w,o4,o4+w,o4+w,lz]'};
pianobench.seat = {'piano_bench:seat', @(lx,ly,lz,hz)[o4,o4,lz-w,lx+w,ly+w,o4+w]'};
models = add_models(models, 'piano_bench', pianobench);

table = [];
table.leg0 = {'table:leg0', @(lx,ly,lz,hz)[o4,o4,o4,o4+w,o4+w,lz]'};
table.leg1 = {'table:leg1', @(lx,ly,lz,hz)[o4,ly-w,o4,o4+w,o4+w,lz]'};
table.leg2 = {'table:leg2', @(lx,ly,lz,hz)[lx-w,o4,o4,o4+w,o4+w,lz]'};
table.leg3 = {'table:leg3', @(lx,ly,lz,hz)[lx-w,ly-w,o4,o4+w,o4+w,lz]'};
table.top = {'table:top', @(lx,ly,lz,hz)[o4,o4,lz-w,lx,ly,o4+w]'};
models = add_models(models, 'table', table);

diningtable = [];
diningtable.leg0 = {'dining_table:leg0', @(lx,ly,lz,hz)[o4,o4,o4,o4+w,o4+w,lz]'};
diningtable.leg1 = {'dining_table:leg1', @(lx,ly,lz,hz)[o4,ly-w,o4,o4+w,o4+w,lz]'};
diningtable.leg2 = {'dining_table:leg2', @(lx,ly,lz,hz)[lx-w,o4,o4,o4+w,o4+w,lz]'};
diningtable.leg3 = {'dining_table:leg3', @(lx,ly,lz,hz)[lx-w,ly-w,o4,o4+w,o4+w,lz]'};
diningtable.top = {'dining_table:top', @(lx,ly,lz,hz)[o4,o4,lz-w,lx,ly,o4+w]'};
models = add_models(models, 'dining_table', diningtable);

desk = [];
desk.leg0 = {'desk:leg0', @(lx,ly,lz,hz)[o4,o4,o4,o4+w,o4+w,lz]'};
desk.leg1 = {'desk:leg1', @(lx,ly,lz,hz)[o4,ly-w,o4,o4+w,o4+w,lz]'};
desk.leg2 = {'desk:leg2', @(lx,ly,lz,hz)[lx-w,o4,o4,o4+w,o4+w,lz]'};
desk.leg3 = {'desk:leg3', @(lx,ly,lz,hz)[lx-w,ly-w,o4,o4+w,o4+w,lz]'};
desk.top = {'desk:top', @(lx,ly,lz,hz)[o4,o4,lz-w,lx,ly,o4+w]'};
models = add_models(models, 'desk', desk);

sofa = [];
sofa.back = {'sofa:back', @(lx,ly,lz,hz)[o4,o4,o4,o4+w,ly,hz]'};
sofa.seat = {'sofa:seat', @(lx,ly,lz,hz)[o4,o4,o4,lx,ly,lz]'};
models = add_models(models, 'sofa', sofa);

bed = [];
bed.head = {'bed:head', @(lx,ly,lz,hz)[o4,o4,o4,o4+w,ly,hz]'};
bed.rear = {'bed:rear', @(lx,ly,lz,hz)[lx,o4,o4,o4,ly,lz]'};
bed.mattress = {'bed:mattress', @(lx,ly,lz,hz)[o4,o4,o4,lx,ly,lz]'};
models = add_models(models, 'bed', bed);

function models = add_models(models, objectname, objmodel)
subobjs = fieldnames(objmodel);
models.objindex = [models.objindex {length(models.subobjs)+1:length(models.subobjs)+length(subobjs)}];
models.objects = [models.objects, objectname];
for subobj = subobjs'
    models = add_model(models, objmodel.(subobj{1}){1}, objmodel.(subobj{1}){2});
end

function models = add_model(models, subobjname, transform)
models.subobjs = [models.subobjs, {subobjname}];
identity = num2cell(eye(4), 1);
models.cuboids_mat = cat(3, models.cuboids_mat, transform(identity{:}));
models.cuboids = [models.cuboids, {transform}];
