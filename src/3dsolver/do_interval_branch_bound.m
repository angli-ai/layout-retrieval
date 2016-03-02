function layouts = do_interval_branch_bound(X0, config)
% enumerate directions
Nobj = length(config.relation.nouns);
X0 = X0(1:Nobj*4, :);
layouts = {};
dir_index = (1:Nobj)*4;
index = find(X0(dir_index, 1) ~= X0(dir_index, 2));
index = dir_index(index);
Ndir = length(index);

assert(Ndir < 10, 'support at most 10 directions');

dir_val = uint8(dec2bin(1:(2^Ndir-1), Ndir)) - uint8('0');

% enumerate orientations
for i = 1:size(dir_val, 1)
    X = X0;
    X(index, :) = [dir_val(i, :); dir_val(i, :)]';
    [ok, X] = direction_check_ok(X, config);
    if ok
        layouts = [layouts, interval_analysis(X, config)];
    end
end

function layouts = interval_analysis(X0, config)

layouts = {};

boundmap = build_boundmap(config, X0);


import java.util.LinkedList
q = LinkedList();
q.add(X0);

unit = 0.2;

while ~q.isEmpty()
    X = q.getFirst;
    q.remove();
    X = shrink(X, boundmap, unit);
    [X, R] = shrink_and_feasible(config, X, unit);
    [maxdiff, index] = max(X(:, 2) - X(:, 1));
    fprintf(1, 'q.size = %d, maxdiff = %.2f\n', q.size, maxdiff);
    if vector_eq(R, [1, 1])
        % feasible
        layouts = [layouts X];
    elseif vector_eq(R, [0, 0])
        % not feasible
    else
        % possibly feasible
        X1 = X;
        X2 = X;
        % split on orientation first
%         index = find(X(dir_index, 1) ~= X(dir_index, 2));
        % split on 
        if config.relation.againstwall(ceil(index/4))
            k = mod(index, 4);
            if k == 1 && X(index+1,2) ~= 0 || k == 2 && X(index-1,2) ~= 0
                X1(index, 2) = X(index, 1);
                X2(index+3-2*k, 2) = X(index+3-k*2, 1);
                q.add(X1);
                q.add(X2);
                continue;
            end
        end
        mid = (X(index, 1) + X(index, 2)) / 2;
        mid = round(mid / unit) * unit;
        X1(index, 2) = mid;
        X2(index, 1) = mid;
        q.add(X1);
        q.add(X2);
    end
end

% shrink the interval and check feasibility
function [X, R] = shrink_and_feasible(config, X, unit)

[maxdiff, index] = max(X(:, 2) - X(:, 1));

R = [];
% check bounds
Nobj = length(config.relation.nouns);
for i = 1:Nobj
    if config.relation.againstwall(i)
        % against-the-wall objects
        % x = 0 or y = 0
        if X(i*4-3,1) > eps && X(i*4-2,1) > eps
            R = [0, 0];
            return
        end
    end
end

% check mutual exclusive
for i = 1:Nobj
    [p1, q1] = get_coords(config, config.relation.nouns{i}, i, X(i*4, :), X((i-1)*4+(1:3),:));
    for j = i+1:Nobj
        [p2, q2] = get_coords(config, config.relation.nouns{j}, j, X(j*4, :), X((j-1)*4+(1:3),:));
        Rintersect = [1, 1];
        for k = 1:3
            Rintersect = ia.and(Rintersect, ia.lt(max(p1(k,:),p2(k,:)),min(q1(k,:),q2(k,:))));
        end
        if vector_eq(Rintersect, [1, 1])
            R = [0, 0];
            return;
        else
            R = ia.and(R, ia.not(Rintersect));
        end
    end
end

dnear = config.spatial.near;
datt = config.spatial.attach;
            
% check relation
Nrel = length(config.relation.rel);
for i = 1:Nrel
    if ~isempty(R) && vector_eq(R, [0, 0])
        return
    end
    semantic = config.relation.rel(i, :);
    obj1 = get_objectid(semantic{1}, config.relation.nouns);
    obj2 = get_objectid(semantic{2}, config.relation.nouns);
    rel = semantic{3};
    [p1, q1] = get_coords(config, semantic{1}, obj1, X(obj1*4, :), X((obj1-1)*4+(1:3),:));
    [p2, q2] = get_coords(config, semantic{2}, obj2, X(obj2*4, :), X((obj2-1)*4+(1:3),:));

    switch rel
        case {'near', 'close-to'}
            for k = 1:3
                R = ia.and(R, ia.le(max(p1(k,:)-dnear,p2(k,:)),min(q1(k,:)+dnear,q2(k,:))));
            end
%                 b_dist = sqrt(ia_abs(ia_minus(x1, x2)).^2 + ia_abs(ia_minus(y1, y2))).^2;
%                 R = ia_and(R, ia_lt(b_dist, iUnear));
        case 'left'
            for k = 1:3
                R = ia.and(R, ia.le(max(p1(k,:)-datt,p2(k,:)),min(q1(k,:)+datt,q2(k,:))));
            end
            if config.relation.againstwall(obj1) && config.relation.againstwall(obj2)
                R = ia.and(R, ia.equal(X(obj1*4,:), X(obj2*4,:)));
            end
            R = ia.and(R, ia.not(ia.and(ia.le(p1(1, :), p2(1, :)), ia.le(p2(2,:), p1(2, :)))));
%             R = ia_and(R, ia.lt(x1, x2));
%             R = ia_and(R, ia.lt(ia.abs(ia.minus(y1, y2)), iUshift));
        case 'right'
            for k = 1:3
                R = ia.and(R, ia.le(max(p1(k,:)-dnear,p2(k,:)),min(q1(k,:)+dnear,q2(k,:))));
            end
            if config.relation.againstwall(obj1) && config.relation.againstwall(obj2)
                R = ia.and(R, ia.equal(X(obj1*4,:), X(obj2*4,:)));
            end
            R = ia.and(R, ia.not(ia.and(ia.le(p2(1, :), p1(1, :)), ia.le(p1(2,:), p2(2, :)))));
%             R = ia_and(R, ia.lt(x2, x1));
%             R = ia_and(R, ia.lt(ia_abs(ia_minus(y1, y2)), iUshift));
        case {'in_front_of', 'front'}
            R = ia_and(R, ia_lt(y1, y2));
            R = ia_and(R, ia_lt(ia_abs(ia_minus(x1, x2)), iUshift));
        case 'behind'
            R = ia_and(R, ia_lt(y2, y1));
            R = ia_and(R, ia_lt(ia_abs(ia_minus(x1, x2)), iUshift));
            
        case {'side-by-side', 'in-a-row'}
            for k = 1:3
                R = ia.and(R, ia.lt(max(p1(k,:)-dnear,p2(k,:)),min(q1(k,:)+dnear,q2(k,:))));
            end
            
        case 'above'
            for k = 1:3
                R = ia.and(R, ia.lt(max(p1(k,:)-dnear,p2(k,:)),min(q1(k,:)+dnear,q2(k,:))));
            end
            R = ia.and(R, ia.lt(q2(3,:)+datt, p1(3,:)));
            R = ia.and(R, ia.lt(p1(3,:), q2(3,:)+dnear));
            
        case 'on'
            R = ia.and(R, ia.equal(p1(3,:), q2(3,:)));
            % weight center supported.
            tmp = (p1(1,:)+q1(1,:))/2;
            R = ia.and(R, ia.lt(p2(1,:), tmp));
            R = ia.and(R, ia.lt(tmp, q2(1,:)));
            tmp = (p1(2,:)+q1(2,:))/2;
            R = ia.and(R, ia.lt(p2(2,:), tmp));
            R = ia.and(R, ia.lt(tmp, q2(2,:)));
        otherwise
%                 error(['rel' rel ' not found']);
    end
%         disp(semantic);
%     disp(R);
end

% if ~vector_eq(R, [0, 0]) && maxdiff <= unit
%     R = [1, 1];
% end