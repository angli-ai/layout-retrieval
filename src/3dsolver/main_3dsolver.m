% 3dsolver main

inputdir = 'testdata';

relation_mat = '000024.jpg-relation.mat';

relation = load(fullfile(inputdir, relation_mat));

% expand plural nouns and collect size/support info.
relation = relation_preprocess(relation);

% get room config
room.length = [0, 10];
room.width = [0, 10];
room.height = [0, 10];