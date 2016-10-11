% eccv supp plot curves
a = load('outputsungtfree', 'output');
b = load('outputsungtguide', 'output');
output = a.output;
gt_ranks = output.Var2';
det_ranks = output.Var3';
det_ranks_soft = output.Var4';
res_ranks_mean = output.Var5';
res_ranks_max = output.Var6';
ntest = 5050;
h = figure(1);
tableres = plot_curves({det_ranks, res_ranks_max}, ntest, {'det', 'ours max'});
