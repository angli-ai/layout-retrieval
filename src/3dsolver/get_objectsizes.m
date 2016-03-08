function relation = get_objectsizes(relation)
% objectsizes is Nx4, each row is length, width, lower height, higher
% height.
objectnames = relation.nouns;
objectsizes = [];
needsupport = [];
objectclass = {};
for i = 1:length(objectnames)
    if strncmp(objectnames{i}, 'bed', 3)
        % default queen size: (L, W, Hl, Hh) = (2.0, 1.5, 0.75, 1.5)
        objectsizes = [objectsizes; 2.0, 1.5, 0.75, 1.5];
        needsupport = [needsupport, true];
        objectclass = [objectclass, 'bed'];
    elseif strncmp(objectnames{i}, 'pillow', 6)
        objectsizes = [objectsizes; 0.1, 0.5, 0.25, 0.25];
        needsupport = [needsupport, true];
        objectclass = [objectclass, 'pillow'];
    elseif strncmp(objectnames{i}, 'garbage-bin', 10)
        objectsizes = [objectsizes; 0.25, 0.25, 0.5, 0.5];
        needsupport = [needsupport, true];
        objectclass = [objectclass, 'garbage_bin'];
     elseif strncmp(objectnames{i}, 'picture', 7)
        objectsizes = [objectsizes; 0.05, 0.5, 0.5, 0.5];
        needsupport = [needsupport, false];
        objectclass = [objectclass, 'picture'];
    elseif strncmp(objectnames{i}, 'mirror', 6)
        objectsizes = [objectsizes; 0.05, 0.5, 0.5, 0.5];
        needsupport = [needsupport, false];
        objectclass = [objectclass, 'mirror'];
    elseif strncmp(objectnames{i}, 'sink', 4)
        objectsizes = [objectsizes; 0.5, 0.5, 0.25, 0.25];
        needsupport = [needsupport, false];
        objectclass = [objectclass, 'sink'];
    elseif strncmp(objectnames{i}, 'whiteboard', 10)
        objectsizes = [objectsizes; 0.05, 1, 1, 1];
        needsupport = [needsupport, false];
        objectclass = [objectclass, 'whiteboard'];
    elseif strncmp(objectnames{i}, 'sofa', 4)
        objectsizes = [objectsizes; 0.75, 0.75, 0.5, 1];
        needsupport = [needsupport, true];
        objectclass = [objectclass, 'sofa'];
    elseif strncmp(objectnames{i}, 'double-sofa', 11)
        objectsizes = [objectsizes; 0.75, 0.75 * 2, 0.5, 0.75];
        needsupport = [needsupport, true];
        objectclass = [objectclass, 'sofa'];
    elseif strncmp(objectnames{i}, 'triple-sofa', 11)
        objectsizes = [objectsizes; 0.75, 0.75 * 3, 0.5, 0.75];
        needsupport = [needsupport, true];
        objectclass = [objectclass, 'sofa'];
    elseif strncmp(objectnames{i}, 'tv', 2)
        objectsizes = [objectsizes; 0.2, 1.0, 0.6, 0.6];
        needsupport = [needsupport, true];
        objectclass = [objectclass, 'tv'];
    elseif strncmp(objectnames{i}, 'monitor', 7)
        objectsizes = [objectsizes; 0.1, 0.3, 0.3, 0.3];
        needsupport = [needsupport, true];
        objectclass = [objectclass, 'monitor'];
    elseif strncmp(objectnames{i}, 'lamp', 4)
        objectsizes = [objectsizes; 0.25, 0.25, 0.5, 0.5];
        needsupport = [needsupport, true];
        objectclass = [objectclass, 'lamp'];
    elseif strncmp(objectnames{i}, 'dresser', 7)
        objectsizes = [objectsizes; 0.25, 1.5, 1.0, 1.0];
        needsupport = [needsupport, true];
        objectclass = [objectclass, 'dresser'];
    elseif strncmp(objectnames{i}, 'cabinet', 7)
        objectsizes = [objectsizes; 0.5, 1.0, 0.5, 0.5];
        needsupport = [needsupport, true];
        objectclass = [objectclass, 'cabinet'];
    elseif strncmp(objectnames{i}, 'chair', 5)
        objectsizes = [objectsizes; 0.5, 0.5, 0.5, 1.0];
        needsupport = [needsupport, true];
        objectclass = [objectclass, 'chair'];
    elseif strncmp(objectnames{i}, 'table', 5)
        objectsizes = [objectsizes; 0.8, 0.8, 0.8, 0.8];
        needsupport = [needsupport, true];
        objectclass = [objectclass, 'table'];
    elseif strncmp(objectnames{i}, 'desk', 4)
        objectsizes = [objectsizes; 0.8, 1.6, 0.8, 0.8];
        needsupport = [needsupport, true];
        objectclass = [objectclass, 'desk'];
    elseif strncmp(objectnames{i}, 'night-stand', 11)
        objectsizes = [objectsizes; 0.5, 0.5, 0.75, 0.75];
        needsupport = [needsupport, true];
        objectclass = [objectclass, 'night_stand'];
    elseif strncmp(objectnames{i}, 'box', 3)
        objectsizes = [objectsizes; 0.5, 0.5, 0.5, 0.5];
        needsupport = [needsupport, true];
        objectclass = [objectclass, 'box'];
    elseif strncmp(objectnames{i}, 'piano-bench', 11)
        objectsizes = [objectsizes; 0.5, 1.0, 0.5, 0.5];
        needsupport = [needsupport, true];
        objectclass = [objectclass, 'piano_bench'];
    elseif strncmp(objectnames{i}, 'piano', 5)
        objectsizes = [objectsizes; 1.0, 1.8, 1.0, 1.0];
        needsupport = [needsupport, true];
        objectclass = [objectclass, 'piano'];
    else % default size
        objectsizes = [objectsizes; 0.5, 0.5, 0.5, 0.5];
        needsupport = [needsupport, true];
        objectclass = [objectclass, 'unknown'];
    end
end
relation.sizes = objectsizes;
relation.class = objectclass;
relation.support = needsupport;
relation.againstwall = [];
for i = 1:length(objectclass)
    switch relation.class{i}
        case {'dresser', 'bed', 'night-stand', 'picture', 'whiteboard', 'mirror', 'sink'}
            relation.againstwall(i) = true;
        otherwise
            relation.againstwall(i) = false;
    end
end
% check against wall
for i = 1:length(relation.wallobj)
    objid = strcmp(relation.wallobj{i}, relation.nouns);
    relation.againstwall(objid) = true;
end