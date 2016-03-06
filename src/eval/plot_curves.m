function plot_curves(ranks, ntot, methods)
nmethod = length(ranks);
curvedata = {};
aucdata = [];
for i = 1:nmethod
    data = zeros(1, ntot);
    Ntest = length(ranks{i});
    for j = 1:Ntest
        data(ranks{i}(j)) = data(ranks{i}(j)) + 1;
    end
%     data(ranks{i}) = 1;
    cumdata = cumsum(data)/Ntest;
    auc = sum(cumdata) / ntot;
    curvedata = [curvedata, (1:ntot)/ntot, cumdata];
    aucdata = [aucdata, auc];
end
plot(curvedata{:}, 'LineWidth', 2);
grid on;
xlabel('Percentage of top ranked images');
ylabel('Percentage of ground truth retrieved');
xlim([0, 1]);
for i = 1:nmethod
    methods{i} = [methods{i} ': auc=' num2str(aucdata(i), '%.2f')];
end
legend(methods{:}, 'Location', 'southeast');
% title('Old 3d solver on 3dgp dataset');
set(gca, 'fontsize', 15);
% saveas(h, 'old-3dsolver-3dgp.jpg');