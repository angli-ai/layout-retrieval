function sols = sample_feasible_sols(A, bounds, Nsols)
dim = size(A, 2) - 1;
num_constraints = size(A, 1);
lb = 0;
ub = bounds(1);
sols = zeros(dim, Nsols);
for i = 1:Nsols
    c = rand(dim, 1);
    x = linprog(c, A(:, 1:dim), -A(:, end), [], [], lb * zeros(dim, 1), ub * zeros(dim, 1));
    sols(:, i) = x;
end
