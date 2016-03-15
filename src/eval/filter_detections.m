objnames = {'bed', 'chair', 'dining_table', 'side_table', 'sofa', 'table'};
thresholds = [0.1247, -0.1395, -0.0043, -0.7429, -0.0961, -0.8231];

dataset = '3dgp';
detection_dir = fullfile('detection-box', dataset);

detection = load(fullfile(detection_dir, 'detection_test-all.mat'));

for i = 1:length(detection.detection)
    det = detection.detection{i};
    det_k = [];
    for k = 1:6
        index = strcmp(det.classname, objnames{k});
        new_det = det(index, :);
        new_det.conf = new_det.conf - thresholds(k);
        new_det = new_det(new_det.conf > 0, :);
        det_k = [det_k; new_det];
    end
    detection.detection_all{i} = det;
    detection.detection{i} = det_k;
end
save(fullfile(detection_dir, 'detection_test.mat'), '-struct', 'detection');