function [ok, X] = direction_check_ok(X, config)
Nobj = length(config.relation.nouns);

% update objects against the wall.
for i = 1:Nobj
    if config.relation.againstwall(i)
        % update picture location
        if X(i*4, 1) == 0
            % at y=0
            X(i*4-2, :) = [0 0];
        elseif X(i*4, 1) == 1
            % at x=0
            X(i*4-3, :) = [0 0];
        end
    end
end

Nrel = size(config.relation.rel, 1);
ok = true;
for i = 1:Nrel
    switch config.relation.rel{i, 3}
        case {'left', 'right'}
%             id1 = get_objectid(config.relation.rel{i, 1}, config.relation.nouns);
%             id2 = get_objectid(config.relation.rel{i, 2}, config.relation.nouns);
%             if config.relation.againstwall(id1) && config.relation.againstwall(id2) ...
%                     && ~vector_eq(X(id1*4, :), X(id2*4, :))
%                 ok = false;
%                 return;
%             end
        case {'on', 'side-by-side', 'in-a-row', 'next-to'}
            id1 = get_objectid(config.relation.rel{i, 1}, config.relation.nouns);
            id2 = get_objectid(config.relation.rel{i, 2}, config.relation.nouns);
            if sum(X(id1*4, :) == X(id2*4, :)) == 0
                ok = false;
                return;
            end
        case 'above'
            id1 = get_objectid(config.relation.rel{i, 1}, config.relation.nouns);
            
            objs = config.relation.rel{i, 2};
            if ~iscell(objs)
                objs = {objs};
            end
            for k = 1:length(objs)
                objk = objs{k};
                id2 = get_objectid(objk, config.relation.nouns);
                if strcmp(config.relation.class{id1}, 'picture')
                    if X(id1*4, 1) ~= X(id2*4, 1) ...
                            || X(id1*4, 2) ~= X(id2*4, 2)
                        ok = false;
                        return;
                    else
                        % update bed and picture location
                        if X(id1*4, 1) == 0
                            % at y=0
                            X(id1*4-2, :) = [0 0];
                            X(id2*4-2, :) = [0 0];
                        elseif X(id1*4, 1) == 1
                            % at x=0
                            X(id1*4-3, :) = [0 0];
                            X(id2*4-3, :) = [0 0];
                        end
                    end
                end
            end
    end
end

