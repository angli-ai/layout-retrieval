% interval analysis
function Y = lt(A, B)
    if B(2) <= A(1)
        Y = [0, 0];
    elseif A(2) <= B(1)
        Y = [1, 1];
    else
        Y = [0, 1];
    end
