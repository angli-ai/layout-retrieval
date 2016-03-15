function R = or(A, B)
R = ia.not(ia.and(ia.not(A), ia.not(B)));