% solve feasible solution space for given model and object relations
% input:
% - Nobjs: # of objects
% - semantics: cell array of object spatial relations
% - model: model parameters.
function [layouts, tot] = solve_by_interval_analysis(Nobjs, semantics, boundmap, model)
% solution space dimension
dim = Nobjs * 2;

layouts = {};
tot = 0;
for i = 1:Nobjs
    for j = 1:Nobjs
        disp([num2str(i), ' - ' num2str(j) ' : ' num2str(length(layouts))]);
        ix = randi(Nobjs);
        iy = randi(Nobjs);
        X = repmat([0 5], dim, 1);
        X(i * 2 - 1, :) = [0 0];
        X(j * 2, :) = [0, 0];
        % find bounds for all other objects
        for k = 1:Nobjs
            if boundmap(1, 1, k, i) > X(k * 2 - 1, 1)
                X(k * 2 - 1, 1) = boundmap(1, 1, k, i);
            end
            if boundmap(2, 1, k, i) < X(k * 2 - 1, 2);
                X(k * 2 - 1, 2) = boundmap(2, 1, k, i);
            end
            if boundmap(1, 2, k, j) > X(k * 2, 1)
                X(k * 2, 1) = boundmap(1, 2, k, j);
            end
            if boundmap(2, 2, k, j) < X(k * 2, 2)
                X(k * 2, 2) = boundmap(2, 2, k, j);
            end
        end
        [layout, cnt] = solve(X, semantics, boundmap);
        tot = tot + cnt
        if ~isempty(layout)
            if length(layout) > 10
                layout = layout(randperm(length(layout), 10));
            end
            layouts = [layouts layout];
        end
    end
end

function [layouts, tot] = solve(X, semantics, boundmap)
layouts = {};
import java.util.LinkedList
q = LinkedList();
q.add(X);
unit = 0.2;
tot = 0;
while ~q.isEmpty() && length(layouts) <= 1000
    X = q.getFirst;
    [maxdiff, index] = max(X(:, 2) - X(:, 1));
    normdiff = norm(X(:, 2) - X(:, 1));
%     if q.size > 1e5
%         break
%     end
%     disp(['length of q = ' num2str(q.size()) ' maxdiff = ' num2str(maxdiff) ' normdiff = ' num2str(normdiff) ' #layouts = ' num2str(length(layouts))]);
    q.remove();
    disp(q.size);
    disp(X);
    R = feasible(semantics, boundmap, X);
    if ia_equal(R, [1, 1])
        % there might be too many intervals!
        % todo: change this to random replacement
        if length(layouts) < 1000
            layouts = [layouts X];
            disp(size(layouts));
        end
        tot = tot + 1;
%         if length(layouts) > 0
%             break
%         end
    elseif ia_equal(R, [0, 0])
        % discard
    else
        if maxdiff <= unit + eps
            continue;
            % interval becomes small enough but still uncertain
            % todo: change to random replacement
            if length(layouts) < 1000
                layouts = [layouts X];
                disp(size(layouts));
            end
            tot = tot + 1;
%             break;
            continue;
        end
        X1 = X;
        X2 = X;
        mid = (X(index, 1) + X(index, 2)) / 2;
        mid = round(mid / unit) * unit;
        X1(index, 2) = mid;
        if X1(index, 2) - X1(index, 1) < unit + eps
            X1(index, :) = mean(X1(index, :));
        end
        X1 = update_bounds(X1, boundmap, index, unit);
        X2(index, 1) = mid;
        if X2(index, 2) - X2(index, 1) < unit + eps
            X2(index, :) = mean(X2(index, :));
        end
        X2 = update_bounds(X2, boundmap, index, unit);
        
        q.add(X1);
        q.add(X2);
    end
end

function X = update_bounds(X, boundmap, index, unit)
Nobjs = size(X, 1) / 2;
while index > 0
    if mod(index, 2) == 0
        % Y-dim
        u = index / 2;
        for k = 1:Nobjs
            if boundmap(1, 2, k, u) + X(index, 1) > X(k * 2, 1)
                X(k * 2, 1) = boundmap(1, 2, k, u) + X(index, 1);
            end
            if boundmap(2, 2, k, u) + X(index, 2) < X(k * 2, 2)
                X(k * 2, 2) = boundmap(2, 2, k, u) + X(index, 2);
            end
        end
    else
        % X-dim
        u = (index + 1) / 2;
        for k = 1:Nobjs
            if boundmap(1, 1, k, u) + X(index, 1) > X(k * 2 - 1, 1)
                X(k * 2 - 1, 1) = boundmap(1, 1, k, u) + X(index, 1);
            end
            if boundmap(2, 1, k, u) + X(index, 2) < X(k * 2 - 1, 2);
                X(k * 2 - 1, 2) = boundmap(2, 1, k, u) + X(index, 2);
            end
        end
    end
    index = 0;
    for i = 1:size(X, 1)
        if X(i, 2) - X(i, 1) > eps && X(i, 2) - X(i, 1) < unit + eps
            X(i, :) = mean(X(i, :));
            index = i;
            break;
        end
    end
end

function R = feasible(semantics, boundmap, X)
%     if min(X(1:2:end, 1)) > 0 || min(X(2:2:end, 1)) > 0
%         R = [0, 0];
%         return;
%     end
    R = [1, 1];
    N = size(X, 1) / 2;
    for i = 1:N-1
        for j = i+1:N
            x1 = X(i*2-1, :);
            y1 = X(i*2, :);
            x2 = X(j*2-1, :);
            y2 = X(j*2, :);
            % check boundmap
            x1_x2 = ia_minus(x1, x2);
            y1_y2 = ia_minus(y1, y2);
            if x1_x2(1) > boundmap(2, 1, i, j) ...
                    || x1_x2(2) < boundmap(1, 1, i, j) ...
                    || y1_y2(1) > boundmap(2, 2, i, j) ...
                    || y1_y2(2) < boundmap(1, 2, i, j)
                R = [0, 0];
                return
            end
            % check common sense: exclusive
            iLmin = [0.1 0.1] + 1;
            b_dist = sqrt(ia_abs(x1_x2).^2 + ia_abs(y1_y2).^2);
            R = ia_and(R, ia_lt(iLmin, b_dist));
            if ia_equal(R, [0, 0])
                return
            end
        end
    end
    for i = 1:length(semantics)
        obj1 = semantics{i}{1};
        obj2 = semantics{i}{2};
        rel = semantics{i}{3};
        x1 = X(obj1*2-1,:);
        y1 = X(obj1*2,:);
        x2 = X(obj2*2-1,:);
        y2 = X(obj2*2,:);
        dist = semantics{i}{4};
        Unear = 0.5;
        Lmin = 0.1;
        iUnear = [Unear Unear] + dist;
        iLmin = [Lmin Lmin] + dist;
        Ushift = 0.2;
        iUshift = [Ushift Ushift];
%         R = ia_and(R, ia_lt(iLmin, b_dist));
%         if ia_equal(R, [0, 0])
%             break
%         end

        b_dist = sqrt(ia_abs(ia_minus(x1, x2)).^2 + ia_abs(ia_minus(y1, y2)).^2);
        R = ia_and(R, ia_lt(b_dist, iUnear));
        switch rel
            case 'near'
%                 b_dist = sqrt(ia_abs(ia_minus(x1, x2)).^2 + ia_abs(ia_minus(y1, y2))).^2;
%                 R = ia_and(R, ia_lt(b_dist, iUnear));
            case 'left'
                R = ia_and(R, ia_lt(x1, x2));
                R = ia_and(R, ia_lt(ia_abs(ia_minus(y1, y2)), iUshift));
            case 'right'
                R = ia_and(R, ia_lt(x2, x1));
                R = ia_and(R, ia_lt(ia_abs(ia_minus(y1, y2)), iUshift));
            case {'in_front_of', 'front'}
                R = ia_and(R, ia_lt(y1, y2));
                R = ia_and(R, ia_lt(ia_abs(ia_minus(x1, x2)), iUshift));
            case 'behind'
                R = ia_and(R, ia_lt(y2, y1));
                R = ia_and(R, ia_lt(ia_abs(ia_minus(x1, x2)), iUshift));
            otherwise
%                 error(['rel' rel ' not found']);
        end
        
        if ia_equal(R, [0, 0])
            break
        end
    end

function Y = ia_lt(A, B)
    if B(2) <= A(1) + eps
        Y = [0, 0];
    elseif A(2) <= B(1)
        Y = [1, 1];
    else
        Y = [0, 1];
    end
    
function Y = ia_gt(A, B)
    Y = ia_lt(B, A);
    
function Y = ia_abs(A)
    if A(1) <= 0 && A(2) <= 0
        Y = [-A(2), -A(1)];
    elseif A(1) <= 0 && A(2) >= 0
        Y = [0, max(-A(1), A(2))];
    else
        Y = A;
    end

function Y = ia_minus(A, B)
    Y = [A(1) - B(2), A(2) - B(1)];

function Y = ia_equal(A, B)
    Y = A(1) == B(1) & A(2) == B(2);

function Y = ia_and(A, B)
    if isempty(A) 
        Y = B;
    elseif isempty(B)
        Y = A;
    elseif ia_equal(A, [0, 0]) || ia_equal(B, [0, 0])
        Y = [0, 0];
    elseif ia_equal(A, [1, 1]) && ia_equal(B, [1, 1])
        Y = [1, 1];
    else
        Y = [0, 1];
    end
