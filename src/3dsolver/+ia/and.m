
function Y = and(A, B)
    if isempty(A) 
        Y = B;
    elseif isempty(B)
        Y = A;
    elseif vector_eq(A, [0, 0]) || vector_eq(B, [0, 0])
        Y = [0, 0];
    elseif vector_eq(A, [1, 1]) && vector_eq(B, [1, 1])
        Y = [1, 1];
    else
        Y = [0, 1];
    end