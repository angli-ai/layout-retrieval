function R = not(a)
if vector_eq(a, [0 1])
    R = a;
else
    R = 1 - a;
end