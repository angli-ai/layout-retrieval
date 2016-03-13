function layouts = do_interval_branch_bound(X0, config, nsamples)
% enumerate directions
Nobj = length(config.relation.nouns);
X0 = X0(1:Nobj*4, :);
layouts = {};
dir_index = (1:Nobj)*4;
index = find(X0(dir_index, 1) ~= X0(dir_index, 2));
index = dir_index(index);
Ndir = length(index);
multidir_index = find(config.relation.multidir) * 4;
multidir_index = intersect(multidir_index, index);
Nmultidir = length(multidir_index);

assert(Ndir < 10, 'support at most 10 directions');

dir_val = uint8(dec2bin(0:(2^(Ndir)-1), Ndir)) - uint8('0');
dir_val = dir_val(randperm(size(dir_val, 1)), :);

Nmultidir = 0;
dir_multidir = uint8(dec2bin(0:(2^(Nmultidir)-1), Nmultidir)) - uint8('0');

% enumerate orientations
num_found = 0;
% multidir_index = [zeros(Nobj, 3); config.relation.multidir];
% multidir_index = logical(multidir_index(:));
for i = 1:size(dir_val, 1)
%     for j = 1:size(dir_multidir, 1)
    X = X0;
    X(index, :) = [dir_val(i, :); dir_val(i, :)]';
%     X(multidir_index, :) = X(multidir_index, :) + double([dir_multidir(j, :); dir_multidir(j, :)]');
    [ok, X] = direction_check_ok(X, config);
    if ok
        current_layout = random_interval_analysis(X, config, nsamples);
        layouts = [layouts current_layout];
        if ~isempty(current_layout)
            num_found = num_found + 1;
            if num_found == nsamples
                break;
            end
        end
    end
%     end
end

if Ndir == 0
    X = X0;
    [ok, X] = direction_check_ok(X, config);
    if ok
        layouts = [layouts, random_interval_analysis(X, config, nsamples)];
    end
end

function X = random_sol(X)
n = size(X, 1);
X(:, 1) = X(:, 1) + (X(:, 2) - X(:, 1)) .* rand(n, 1);
X(:, 2) = X(:, 1);

function layouts = check_random_sol(config, q, unit)
Xrand = random_sol(q);
[Xrand, R] = shrink_and_feasible(config, Xrand, unit);
if vector_eq(R, [1, 1])
    % feasible
    layouts = Xrand;
else
    layouts = {};
end

function layouts = random_interval_analysis(X0, config, nsamples)

layouts = {};

boundmap = build_boundmap(config, X0);

q = zeros(size(X0, 1), size(X0, 2), 0);
q = cat(3, q, X0);
N = 1;

unit = 0.2;

maxN = 1000;

global starttime

while N > 0 && length(layouts) < nsamples

    tcost = toc(starttime)
    if tcost > 3600
        break;
    end
    X = q(:, :, N);
    N = N - 1;
    X = shrink(X, boundmap, unit);
    [X, R] = shrink_and_feasible(config, X, unit);
    [maxdiff, index] = max(X(:, 2) - X(:, 1));
    if ~isempty(find(X(:, 2) < X(:, 1), 1))
        continue;
    end
    fprintf(1, 'q.size = %d, maxdiff = %.2f, #layouts = %d\n', N, maxdiff, length(layouts));
    %if maxdiff < 0.4
        % disp(X);
    %end
%     fprintf(1, 'q.size = %d, maxdiff = %.2f\n', N, maxdiff);
    if vector_eq(R, [1, 1])
        % feasible
        layouts = [layouts X];
    elseif vector_eq(R, [0, 0])
        % not feasible
%         disp(X);
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
                pos1 = randi(N+1);
                if pos1 <= N
                    q(:, :, N+1) = q(:, :, pos1);
                end
                q(:, :, pos1) = X1;
                if N == maxN
                    layouts = [layouts check_random_sol(config, q(:, :, N+1), unit)];
                else
                    N = N + 1;
                end
                pos1 = randi(N+1);
                if pos1 <= N
                    q(:, :, N+1) = q(:, :, pos1);
                end
                q(:, :, pos1) = X2;
                if N == maxN
                    layouts = [layouts check_random_sol(config, q(:, :, N+1), unit)];
                else
                    N = N + 1;
                end
                continue;
            end
        end
        mid = (X(index, 1) + X(index, 2)) / 2;
        mid = round(mid / unit) * unit;
        X1(index, 2) = mid;
        X2(index, 1) = mid;
        pos1 = randi(N+1);
        if pos1 <= N
            q(:, :, N+1) = q(:, :, pos1);
        end
        q(:, :, pos1) = X1;
        if N == maxN
            layouts = [layouts, check_random_sol(config, q(:, :, N+1), unit)];
        else
            N = N + 1;
        end
        pos1 = randi(N+1);
        if pos1 <= N
            q(:, :, N+1) = q(:, :, pos1);
        end
        q(:, :, pos1) = X2;
        if N == maxN
            layouts = [layouts check_random_sol(config, q(:, :, N+1), unit)];
        else
            N = N + 1;
        end
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
    fprintf(1, 'q.size = %d, maxdiff = %.2f, #layouts\n', q.size, maxdiff, length(layouts));
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

if sum(X(:, 1) > X(:, 2) + eps) > 0
    R = [0, 0];
    return;
end

[maxdiff, index] = max(X(:, 2) - X(:, 1));

Nrel = size(config.relation.rel, 1);

% re-direction
for i = 1:Nrel
    semantic = config.relation.rel(i, :);
    if strcmp(semantic{3}, 'under') && strncmp(semantic{1}, 'chair', 5)
        obj1 = get_objectid(semantic{1}, config.relation.nouns);
        obj2 = get_objectid(semantic{2}, config.relation.nouns);
            
        if vector_eq(X(obj1*4, :), [0, 0])
            [p1, q1] = get_coords(config, semantic{1}, obj1, X(obj1*4, :), X((obj1-1)*4+(1:3),:));
            [p2, q2] = get_coords(config, semantic{2}, obj2, X(obj2*4, :), X((obj2-1)*4+(1:3),:));
            if vector_eq(ia.lt(p2(2, :), p1(2, :)), [1, 1])
                X(obj1*4, :) = [2, 2];
            end
        elseif vector_eq(X(obj1*4, :), [1, 1])
            [p1, q1] = get_coords(config, semantic{1}, obj1, X(obj1*4, :), X((obj1-1)*4+(1:3),:));
            [p2, q2] = get_coords(config, semantic{2}, obj2, X(obj2*4, :), X((obj2-1)*4+(1:3),:));
            if vector_eq(ia.lt(p2(1, :), p1(1, :)), [1, 1])
                X(obj1*4, :) = [3, 3];
            end
        end
    end
end


R = [1, 1];
% check bounds
Nobj = length(config.relation.nouns);
for i = 1:Nobj
    if X(i*4-3,2) < eps && X(i*4-2,2) < X(config.x0index*4-2,1) - eps
        R = [0, 0];
        return;
    end
    if X(i*4-2,2) < eps && X(i*4-3,2) < X(config.y0index*4-3,1) - eps
        R = [0, 0];
        return;
    end
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
coords = cell(1, Nobj);
for i = 1:Nobj
    coords{i} = get_model_coords(config, config.relation.nouns{i}, i, X(i*4, :), X((i-1)*4+(1:3),:));
end
for i = 1:Nobj
    coordi = coords{i};
    for ii = 1:length(coordi)
        coordii = coordi{ii};
        for j = i+1:Nobj
            coordj = coords{j};
            for jj = 1:length(coordj)
                coordjj = coordj{jj};
                Rintersect = [1, 1];
                for k = 1:3
                    Rintersect = ia.and(Rintersect, ia.lt(max(coordii{1}(k,:),coordjj{1}(k,:)),min(coordii{2}(k,:),coordjj{2}(k,:))));
                end
                if vector_eq(Rintersect, [1, 1])
                    % intersect
                    R = [0, 0];
                    return;
                else
                    R = ia.and(R, ia.not(Rintersect));
                end
            end
        end
    end
end

dnear = config.spatial.near;
datt = config.spatial.attach;
            
% check relation
for i = 1:Nrel
    if ~isempty(R) && vector_eq(R, [0, 0])
        return
    end
    semantic = config.relation.rel(i, :);
    obj1 = get_objectid(semantic{1}, config.relation.nouns);
    rel = semantic{3};
    [p1, q1] = get_coords(config, semantic{1}, obj1, X(obj1*4, :), X((obj1-1)*4+(1:3),:));
    if iscell(semantic{2})
        p2 = repmat([inf, -inf], 3, 1);
        q2 = p2; z2 = [inf, -inf];
        for j = 1:length(semantic{2})
            obj2j = get_objectid(semantic{2}{j}, config.relation.nouns);
            [p2j, q2j, z2j] = get_coords(config, semantic{2}{j}, obj2j, X(obj2j*4, :), X((obj2j-1)*4+(1:3),:));
            p2(:, 1) = min(p2(:, 1), p2j(:, 1));
            p2(:, 2) = max(p2(:, 2), p2j(:, 2));
            q2(:, 1) = min(q2(:, 1), q2j(:, 1));
            q2(:, 2) = max(q2(:, 2), q2j(:, 2));
            z2(1) = min(z2(1), z2j(1));
            z2(2) = max(z2(2), z2j(2));
        end
    else
        obj2 = get_objectid(semantic{2}, config.relation.nouns);
        [p2, q2, z2] = get_coords(config, semantic{2}, obj2, X(obj2*4, :), X((obj2-1)*4+(1:3),:));
    end

    switch rel
        case {'near', 'close-to'}
            for k = 1:3
                R = ia.and(R, ia.le(max(p1(k,:)-dnear,p2(k,:)),min(q1(k,:)+dnear,q2(k,:))));
            end
%                 b_dist = sqrt(ia_abs(ia_minus(x1, x2)).^2 + ia_abs(ia_minus(y1, y2))).^2;
%                 R = ia_and(R, ia_lt(b_dist, iUnear));
        case 'attach'
            for k = 1:3
                R = ia.and(R, ia.le(max(p1(k,:)-datt,p2(k,:)),min(q1(k,:)+datt,q2(k,:))));
            end
        case 'next-to'
            for k = 1:3
                R = ia.and(R, ia.le(max(p1(k,:)-datt,p2(k,:)),min(q1(k,:)+datt,q2(k,:))));
            end
            if config.relation.againstwall(obj1) && config.relation.againstwall(obj2)
                R = ia.and(R, ia.equal(X(obj1*4,:), X(obj2*4,:)));
            end
            R = ia.and(R, ia.or(...
                ia.left(p1, q1, d1, p2, q2, d2, datt), ...
                ia.right(p1, q1, d1, p2, q2, d2, datt)));
        case 'left'
            d1 = X(obj1*4,:);
            d2 = X(obj2*4,:);
%             if config.relation.againstwall(obj1) && config.relation.againstwall(obj2)
%                 R = ia.and(R, ia.equal(d1, d2));
%             end
            R = ia.and(R, ia.left(p1, q1, d1, p2, q2, d2, dnear));
        case 'right'
            d1 = X(obj1*4,:);
            d2 = X(obj2*4,:);
%             if config.relation.againstwall(obj1) && config.relation.againstwall(obj2)
%                 R = ia.and(R, ia.equal(d1, d2));
%             end
            if ~config.relation.support(obj1) && ~config.relation.support(obj2)
                if X(obj1*4,2) == 0
                    R = ia.and(R, ia.right(p1([1 3 2],:), q1([1 3 2],:), d1, p2([1 3 2],:), q2([1 3 2],:), d2, dnear));
                elseif X(obj1*4,2) == 1
                    R = ia.and(R, ia.right(p1([3 2 1],:), q1([3 2 1],:), d2, p2([3 2 1],:), q2([3 2 1],:), d2, dnear));
                end
            else
                R = ia.and(R, ia.right(p1, q1, d1, p2, q2, d2, dnear));
            end
        case {'in_front_of', 'front'}
            R = ia.and(R, ia.front(p1, q1, X(obj1*4,:), p2, q2, X(obj2*4,:), dnear));
        case 'behind'
            R = ia.and(R, ia.behind(p1, q1, X(obj1*4,:), p2, q2, X(obj2*4,:), dnear));
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
            R = ia.and(R, ia.equal(p1(3,:), z2));
            % weight center supported.
            tmp = (p1(1,:)+q1(1,:))/2;
            R = ia.and(R, ia.lt(p2(1,:), tmp));
            R = ia.and(R, ia.lt(tmp, q2(1,:)));
            tmp = (p1(2,:)+q1(2,:))/2;
            R = ia.and(R, ia.lt(p2(2,:), tmp));
            R = ia.and(R, ia.lt(tmp, q2(2,:)));
            
        case 'under'
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
