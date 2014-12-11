function layouts = solve_by_interval_analysis(Nobjs, semantics, model)
dim = Nobjs * 2;
layouts = {};
for i = 1:Nobjs
    for j = 1:Nobjs
        disp([num2str(i), ' - ' num2str(j) ' : ' num2str(length(layouts))]);
        ix = randi(Nobjs);
        iy = randi(Nobjs);
        X = repmat([0 5], dim, 1);
        X(i * 2 - 1, :) = [0 0];
        X(j * 2, :) = [0, 0];
        layout = solve(X, semantics);
        if ~isempty(layout)
            if length(layout) > 10
                layout = layout(randperm(length(layout), 10));
            end
            layouts = [layouts layout];
        end
    end
end

function layouts = solve(X, semantics)
layouts = {};
import java.util.LinkedList
q = LinkedList();
q.add(X);
unit = 0.2;
while ~q.isEmpty()
    X = q.getFirst;
    [maxdiff, index] = max(X(:, 2) - X(:, 1));
    normdiff = norm(X(:, 2) - X(:, 1));
%     if q.size > 1e5
%         break
%     end
%     disp(['length of q = ' num2str(q.size()) ' maxdiff = ' num2str(maxdiff) ' normdiff = ' num2str(normdiff) ' #layouts = ' num2str(length(layouts))]);
    q.remove();
    R = feasible(semantics, X);
    if ia_equal(R, [1, 1])
        layouts = [layouts X];
        disp(size(layouts));
%         if length(layouts) > 0
%             break
%         end
    elseif ia_equal(R, [0, 0])
        % discard
    else
        if maxdiff <= unit + eps
            layouts = [layouts X];
            disp(size(layouts));
%             break;
            continue;
        end
        X1 = X;
        X2 = X;
        mid = (X(index, 1) + X(index, 2)) / 2;
        mid = round(mid / unit) * unit;
        X1(index, 2) = mid;
        X2(index, 1) = mid;
        q.add(X1);
        q.add(X2);
    end
end

function R = feasible(semantics, X)
%     if min(X(1:2:end, 1)) > 0 || min(X(2:2:end, 1)) > 0
%         R = [0, 0];
%         return;
%     end
    R = [];
    N = size(X, 1) / 2;
    for i = 1:N-1
        for j = i+1:N
            x1 = X(i*2-1, :);
            y1 = X(i*2, :);
            x2 = X(j*2-1, :);
            y2 = X(j*2, :);
            iLmin = [0.2 0.2] + 1;
            b_dist = sqrt(ia_abs(ia_minus(x1, x2)).^2 + ia_abs(ia_minus(y1, y2))).^2;
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
        Unear = 0.3;
        Lmin = 0.2;
        iUnear = [Unear Unear] + dist;
        iLmin = [Lmin Lmin] + dist;
        Ushift = 0.2;
        iUshift = [Ushift Ushift];
%         R = ia_and(R, ia_lt(iLmin, b_dist));
%         if ia_equal(R, [0, 0])
%             break
%         end
        b_dist = sqrt(ia_abs(ia_minus(x1, x2)).^2 + ia_abs(ia_minus(y1, y2))).^2;
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
    if B(2) <= A(1)
        Y = [0, 0];
    elseif A(2) <= B(1)
        Y = [1, 1];
    else
        Y = [0, 1];
    end

function Y = ia_abs(A)
    if A(1) < 0 && A(2) < 0
        Y = [-A(2), -A(1)];
    elseif A(1) < 0 && A(2) > 0
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
