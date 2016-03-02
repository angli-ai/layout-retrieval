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
models.subobjs = {};
models.cuboids = {};
models.cuboids_mat = [];

o4 = zeros(4, 1);
chair = [];
chair.back = {'chair:back', @(lx,ly,lz,hz)[o4,o4,lz,o4,ly,hz-lz]'};
chair.leg0 = {'chair:leg0', @(lx,ly,lz,hz)[o4,o4,o4,o4,o4,lz]'};
chair.leg1 = {'chair:leg1', @(lx,ly,lz,hz)[o4,ly,o4,o4,o4,lz]'};
chair.leg2 = {'chair:leg2', @(lx,ly,lz,hz)[lx,o4,o4,o4,o4,lz]'};
chair.leg3 = {'chair:leg3', @(lx,ly,lz,hz)[lx,ly,o4,o4,o4,lz]'};
chair.seat = {'chair:seat', @(lx,ly,lz,hz)[o4,o4,lz,lx,ly,o4]'};
models = add_models(models, chair);

bed = [];
bed.head = {'bed:head', @(lx,ly,lz,hz)[o4,o4,o4,o4,ly,hz]'};
bed.mattress = {'bed:mattress', @(lx,ly,lz,hz)[o4,o4,o4,lx,ly,lz]'};
models = add_models(models, bed);

function models = add_models(models, objmodel)
subobjs = fieldnames(objmodel);
for subobj = subobjs'
    models = add_model(models, objmodel.(subobj{1}){1}, objmodel.(subobj{1}){2});
end

function models = add_model(models, subobjname, transform)
models.subobjs = [models.subobjs, {subobjname}];
identity = num2cell(eye(4), 1);
models.cuboids_mat = cat(3, models.cuboids_mat, transform(identity{:}));
models.cuboids = [models.cuboids, {transform}];
