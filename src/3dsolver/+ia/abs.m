
function Y = abs(A)
    if A(1) < 0 && A(2) < 0
        Y = [-A(2), -A(1)];
    elseif A(1) < 0 && A(2) > 0
        Y = [0, max(-A(1), A(2))];
    else
        Y = A;
    end

