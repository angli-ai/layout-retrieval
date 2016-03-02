
function Y = equal(A, B)
Y = ia.and(ia.le(A, B), ia.le(B, A));
