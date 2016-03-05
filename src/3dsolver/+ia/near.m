function R = near(dnear, p1, q1, p2, q2)
R = [];
for k = 1:3
    R = ia.and(R, ia.le(max(p1(k,:)-dnear,p2(k,:)),min(q1(k,:)+dnear,q2(k,:))));
end