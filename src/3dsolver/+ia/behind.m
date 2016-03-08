function R = behind(p1, q1, d1, p2, q2, d2, dnear)
R = [];
R = ia.and(R, ia.near(dnear, p1, q1, p2, q2));
if vector_eq(d2, [0, 0])
    R = ia.and(R, ia.le(q1(2, :), p2(2, :)));
    R = ia.and(R, ia.le(p2(1, :), (p1(1, :) + q1(1, :))/2));
    R = ia.and(R, ia.le((p1(1, :) + q1(1, :))/2, q2(1, :)));
elseif vector_eq(d2, [1, 1])
    R = ia.and(R, ia.le(q1(1, :), p2(1, :)));
    R = ia.and(R, ia.le(p2(2, :), (p1(2,:) + q1(2, :))/2));
    R = ia.and(R, ia.le((p1(2, :)+q1(2,:))/2, q2(2, :)));
else
    R = ia.and(R, ia.not(ia.and(ia.le(p1(1, :), p2(1, :)), ia.le(p1(2, :), p2(2, :)))));
end