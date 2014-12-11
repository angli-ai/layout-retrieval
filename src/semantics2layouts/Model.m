classdef Model < handle
    properties
        objs
        rels
        map_rels
        map_objs
        room_size
        
        Tn
        delta
    end
    
    methods
        function obj = Model()
            obj.objs = {'bed', 'chair', 'dining-table', 'side-table', 'sofa', 'table'};
            obj.map_objs = containers.Map(obj.objs, 1:length(obj.objs));
            obj.rels = {'near', 'left', 'right', 'front', 'behind', 'above', 'below', 'on'};
            obj.map_rels = containers.Map(obj.rels, 1:length(obj.rels));
            obj.room_size = [10 10 5];
            obj.Tn = 1;
            obj.delta = 1;
        end
        
        function R = get_coeffs_from_rel(obj, Nobjs, obj_i, obj_j, rel)
            dim = Nobjs * 2 + 1;
            index = [obj_i*2-1, obj_i*2, obj_j*2-1, obj_j*2, Nobjs*2+1];
            Tn = obj.Tn;
            delta = obj.delta;
            mindist = 0.5;
            switch rel
                case 'near'
                    R = zeros(4, dim);
                    R(:, index) = [1 -1 1 -1 -Tn; ...
                        -1 1 1 -1 -Tn; ...
                        1 -1 -1 1 -Tn; ...
                        -1 1 -1 1 -Tn];
                case 'left'
                    R = zeros(3, dim);
                    R(:, index) = [1 0 -1 0 mindist; ...
                        0 1 0 -1 -delta; ...
                        0 -1 0 1 -delta];
                case 'right'
                    R = zeros(3, dim);
                    R(:, index) = [-1 0 1 0 mindist; ...
                        0 1 0 -1 -delta; ...
                        0 -1 0 1 -delta];
                case 'front'
                    R = zeros(3, dim);
                    R(:, index) = [0 1 0 -1 mindist; ...
                        1 0 -1 0 -delta; ...
                        -1 0 1 0 -delta];
                case 'behind'
                    R = zeros(3, dim);
                    R(:, index) = [0 -1 0 1 mindist; ...
                        1 0 -1 0 -delta; ...
                        -1 0 1 0 -delta];
                case 'above'
                    error('above is not used.')
                case 'below'
                    error('below is not used.')
                case 'on'
                    error('on is not used')
                otherwise
                    error(['relation [' rel '] not found']);
            end
        end
    end
end

