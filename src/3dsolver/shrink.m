function X = shrink(X, boundmap, tol)

N = boundmap.N;

assert(N*4 == size(X, 1));
for i = 1:N
    xlb = X((i-1)*4+(1:3),1);
    xub = X((i-1)*4+(1:3), 2);
  for j = 1:N
      xlb = max(xlb, X((j-1)*4+(1:3), 1) + boundmap.lb(:, i, j));
      xub = min(xub, X((j-1)*4+(1:3), 2) + boundmap.ub(:, i, j));
  end
  for k = 1:3
      if xub(k) > xlb(k) + eps && xub(k)-xlb(k) < tol * 2
          xub(k) = (xub(k)+xlb(k))/2;
          xlb(k) = xub(k);
      end
  end
  X((i-1)*4+(1:3),:) = [xlb xub];
end