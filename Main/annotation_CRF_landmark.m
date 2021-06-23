
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function for automatic annotation of one whole-brain image stack
% containing neuronal landmarks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% Inputs - 
% 1. data - generated by running 'preprocess_landmark_data.m'. Contains all
%           necessary information required in the code
% 2. numLabelRemove - num of cells to consisdered missing in images
% 3. num - a variable to keep track of iterations if considering missing
%          cells. If not running iterations set to 1

function annotation_CRF_landmark(strain,data,out_file,node_pot_type,numLabelRemove,varargin)

p = inputParser;
addRequired(p,'strain',@checkStrain)
addRequired(p,'data',@ischar)
addRequired(p,'out_file',@ischar)
addRequired(p,'node_pot_type',@checkNodePotType)
addParameter(p,'weights',[0,0,0,0,1],@checkWeights)
parse(p,strain,data,out_file,node_pot_type,varargin{:})

rng shuffle
addpath(genpath('UGM'))

%%% load image data and atlas data
% Change input directories here for your data.
% Static atlas is 'data_neuron_relationship.mat' file provided
load([data,'.mat'])
load('sample_run\data_neuron_relationship_annotation_updated.mat')

%%% remove missing cells from atlas
dont_remove = zeros(size(landmark_names,1),1);
for i = 1:size(dont_remove,1)
    dont_remove(i,1) = find(strcmp(Neuron_head,landmark_names{i,1}));
end
all_dont_remove = [1:1:size(Neuron_head,1)]';
all_dont_remove(dont_remove,:) = [];
ganglion(dont_remove,:) = [];

anterior_index = all_dont_remove(ganglion(:,1) == 1);
lateral_index = all_dont_remove(ganglion(:,1) == 2);
ventral_index = all_dont_remove(ganglion(:,1) == 3);
num_anterior_remove = round(size(anterior_index,1)/size(ventral_index,1)*numLabelRemove/(size(anterior_index,1)/size(ventral_index,1)+size(lateral_index,1)/size(ventral_index,1)+1));
num_lateral_remove = round(size(lateral_index,1)/size(ventral_index,1)*numLabelRemove/(size(anterior_index,1)/size(ventral_index,1)+size(lateral_index,1)/size(ventral_index,1)+1));
num_ventral_remove = numLabelRemove - num_anterior_remove - num_lateral_remove;

remove_anterior = anterior_index(randperm(size(anterior_index,1),num_anterior_remove),:);
remove_lateral = lateral_index(randperm(size(lateral_index,1),num_lateral_remove),:);
remove_ventral = ventral_index(randperm(size(ventral_index,1),num_ventral_remove),:);
remove_index = [remove_anterior;remove_lateral;remove_ventral];
Neuron_head(remove_index,:) = [];
DV_matrix(remove_index,:) = [];
DV_matrix(:,remove_index) = [];
geo_dist(remove_index,:) = [];
geo_dist(:,remove_index) = [];
LR_matrix(remove_index,:) = [];
LR_matrix(:,remove_index) = [];
PA_matrix(remove_index,:) = [];
PA_matrix(:,remove_index) = [];
X_rot(remove_index,:) = [];
Y_rot(remove_index,:) = [];
Z_rot(remove_index,:) = [];
X_rot_norm(remove_index,:) = [];

%%% generate coordinate axes in head
PA = [];
LR = [];
DV = [];
[PA,LR,DV] = generate_coordinate_axes(strain,mu_r,landmark_to_neuron_map,axes_param,axes_neurons_to_neuron_map,landmark_names,ind_PCA,specify_PA);
disp('1. Created axes')
% take neurons coordinates to AP, LR, DV axis
mu_r_centered = mu_r - repmat(mean(mu_r),size(mu_r,1),1);
X = mu_r_centered*PA';
Y = mu_r_centered*LR';
Z = mu_r_centered*DV';
X_norm = (X-min(X))/(max(X)-min(X));


%%% Create spatial neighborhood. Used to calculate proximity realtionship
%%% feature
K = 6;
pos = [mu_r_centered(:,1),mu_r_centered(:,2),mu_r_centered(:,3)];
euc_dist = repmat(diag(pos*pos'),1,size(pos,1)) + repmat(diag(pos*pos')',size(pos,1),1) - 2*pos*pos';
[sort_euc_dist,sort_index] = sort(euc_dist,2);
adj = zeros(size(X,1),size(X,1));
for i = 1:size(adj,1)
    adj(i,sort_index(i,2:K+1)) = 1;
end
adj = max(adj,adj');
G = graph(adj);
geo_dist_r = distances(G);

%%% Calculate Laplacian Family Signatures as node features
% [sOut,tOut] = findedge(G);
% figure,scatter3(X(:,1),Y(:,1),Z(:,1),30,'.r')
% hold on
% for i = 1:size(sOut,1)
%     plot3([X(sOut(i,1));X(tOut(i,1))],[Y(sOut(i,1));Y(tOut(i,1))],[Z(sOut(i,1));Z(tOut(i,1))],'k')
% end
% adj_lfs = exp(-geo_dist_r.^2/(2*max(max(geo_dist_r))));
% D = diag(sum(adj_lfs,2));
% L = D - adj_lfs;
% [eigvec_r,eigval_r] = eig(L);

%%% initialize graphical model
adj = ones(size(X,1),size(X,1)); % fully connected graph structure of CRF
adj = adj - diag(diag(adj));
nStates = size(Neuron_head,1);
nNodes = size(X,1);
edgeStruct = UGM_makeEdgeStruct(adj,nStates);

%%% create node potentials. Two methods can be used to initialize node
%%% potentials. 1) Uniform probability of each node taking each label in
%%% atlas. 2) Potential based on distance along AP axis
if strcmp(node_pot_type,'uniform')
    node_pot =  ones(nNodes,nStates);
elseif strcmp(node_pot_type,'ap')
    loc_sigma = 0.2;
    node_pot = zeros(nNodes,nStates);
    for i = 1:nNodes
        node_pot(i,:) = diag(exp(-((ones(size(X_rot_norm))*X_norm(i,1) - X_rot_norm)*(ones(size(X_rot_norm))*X_norm(i,1) - X_rot_norm)')/(2*loc_sigma^2)))';
    end
elseif strcmp(node_pot_type,'reg')
    addpath(genpath('CPD2'))
    node_pot = reg_based_node_potential(X,Y,Z,X_rot,Y_rot,Z_rot);
elseif strcmp(node_pot_type,'col')
    if isempty(col_atlas)
        disp("Please provide color atlas path (last argument of the function). Exiting.")
    else
        load('Main\all_col_int')
        node_pot = col_based_node_potential(all_col_int,data_int,Neuron_head);
    end
end
orig_node_pot = node_pot;
disp('2. Created node potentials')

%%% create edge potentials
orig_edge_pot = zeros(nStates, nStates, edgeStruct.nEdges);
edge_pot = zeros(nStates, nStates, edgeStruct.nEdges);
lambda_PA = p.Results.weights(1,1);
lambda_LR = p.Results.weights(1,2);
lambda_DV = p.Results.weights(1,3);
lambda_geo = p.Results.weights(1,4);
lambda_angle = p.Results.weights(1,5);
for i = 1:edgeStruct.nEdges
    node1 = edgeStruct.edgeEnds(i,1);
    node2 = edgeStruct.edgeEnds(i,2);
    angle_matrix = get_relative_angles(X_rot,Y_rot,Z_rot,X,Y,Z,node1,node2);
    if X(node1,1) < X(node2,1)
        if Y(node1,1) < Y(node2,1)
            if Z(node1,1) < Z(node2,1)
                pot = exp(lambda_PA*PA_matrix).*exp(lambda_DV*DV_matrix).*exp(lambda_LR*LR_matrix).*exp(exp(-lambda_geo*(geo_dist-geo_dist_r(node1,node2)).^2)).*exp(lambda_angle*angle_matrix);
            else
                pot = exp(lambda_PA*PA_matrix).*exp(lambda_DV*DV_matrix').*exp(lambda_LR*LR_matrix).*exp(exp(-lambda_geo*(geo_dist-geo_dist_r(node1,node2)).^2)).*exp(lambda_angle*angle_matrix);
            end
        else
            if Z(node1,1) < Z(node2,1)
                pot = exp(lambda_PA*PA_matrix).*exp(lambda_DV*DV_matrix).*exp(lambda_LR*LR_matrix').*exp(exp(-lambda_geo*(geo_dist-geo_dist_r(node1,node2)).^2)).*exp(lambda_angle*angle_matrix);
            else
                pot = exp(lambda_PA*PA_matrix).*exp(lambda_DV*DV_matrix').*exp(lambda_LR*LR_matrix').*exp(exp(-lambda_geo*(geo_dist-geo_dist_r(node1,node2)).^2)).*exp(lambda_angle*angle_matrix);
            end
        end
    else
        if Y(node1,1) < Y(node2,1)
            if Z(node1,1) < Z(node2,1)
                pot = exp(lambda_PA*PA_matrix').*exp(lambda_DV*DV_matrix).*exp(lambda_LR*LR_matrix).*exp(exp(-lambda_geo*(geo_dist-geo_dist_r(node1,node2)).^2)).*exp(lambda_angle*angle_matrix);
            else
                pot = exp(lambda_PA*PA_matrix').*exp(lambda_DV*DV_matrix').*exp(lambda_LR*LR_matrix).*exp(exp(-lambda_geo*(geo_dist-geo_dist_r(node1,node2)).^2)).*exp(lambda_angle*angle_matrix);
            end
        else
            if Z(node1,1) < Z(node2,1)
                pot = exp(lambda_PA*PA_matrix').*exp(lambda_DV*DV_matrix).*exp(lambda_LR*LR_matrix').*exp(exp(-lambda_geo*(geo_dist-geo_dist_r(node1,node2)).^2)).*exp(lambda_angle*angle_matrix);
            else
                pot = exp(lambda_PA*PA_matrix').*exp(lambda_DV*DV_matrix').*exp(lambda_LR*LR_matrix').*exp(exp(-lambda_geo*(geo_dist-geo_dist_r(node1,node2)).^2)).*exp(lambda_angle*angle_matrix);
            end
        end
    end
    orig_edge_pot(:, :, i) = pot;
    pot(find(pot<0.01)) = 0.001; %  small potential of incompatible matches
    pot = pot - diag(diag(pot)) + 0.001*eye(size(pot,1)); 
    edge_pot(:,:,i) = pot;
end
disp('3. Created edge potentials')

%%% clamp potential based on landmarks
clamped = zeros(nNodes,1);
if exist('landmark_to_neuron_map','var')
    for i = 1:size(landmark_to_neuron_map,1)
        clamped(landmark_to_neuron_map(i,1),1) = find(strcmp(Neuron_head,landmark_names{i,1}));
    end
end

%%% Optimize graphical model using Loopy Belief Propagation
disp('4. Starting optimization')
[nodeBel,edgeBel,logZ] = UGM_Infer_Conditional(node_pot,edge_pot,edgeStruct,clamped,@UGM_Infer_LBP);
conserved_nodeBel = nodeBel; %node belief matrix to maintain marginal probabilities after clamping in subsequent steps
% optimal_decode = UGM_Decode_Conditional(node_pot,edge_pot,edgeStruct,clamped,@UGM_Decode_LBP);
[sort_nodeBel,nodeBel_sort_index] = sort(nodeBel,2,'descend');
curr_labels = nodeBel_sort_index(:,1);
[PA_score,LR_score,DV_score,geodist_score,tot_score] = consistency_scores(nNodes,curr_labels,X,Y,Z,PA_matrix,LR_matrix,DV_matrix,geo_dist,geo_dist_r);

%%% handle duplicate assignments 
disp('5. Resolving duplicates and re-running optimization')
orig_state_array = [1:1:size(Neuron_head,1)]';
if exist('landmark_to_neuron_map','var')
    clamped_neurons = landmark_to_neuron_map;
end
node_label = duplicate_labels(curr_labels,X,Y,Z,PA_matrix,LR_matrix,DV_matrix,geo_dist,geo_dist_r,img_1,mu_r,Neuron_head,lambda_geo,clamped_neurons);
cnt = 2;
while find(node_label(:,1) == 0)
    assigned_nodes = find(node_label(:,1) ~= 0);
    assigned_labels = node_label(node_label(:,1) ~= 0,1);
    unassigned_nodes = find(node_label(:,1) == 0);
    
    node_pot = orig_node_pot;
    node_pot(unassigned_nodes,assigned_labels) = 0;
    node_pot(find(node_pot<0.001)) = 0.001;
    
    
    edge_pot = zeros(nStates,nStates,edgeStruct.nEdges);
    for i = 1:size(edgeStruct.edgeEnds,1)
        node1 = edgeStruct.edgeEnds(i,1);
        node2 = edgeStruct.edgeEnds(i,2);
        pot = orig_edge_pot(:, :, i);
        if node_label(node1,1) == 0 && node_label(node2,1) == 0 % unassigned-unassigned nodes
            pot(assigned_labels,assigned_labels) = 0;
        elseif node_label(node1,1) == 0 && node_label(node2,1) ~= 0 % unassigned-assigned nodes
            pot(assigned_labels,:) = 0;
        elseif node_label(node1,1) ~= 0 && node_label(node2,1) == 0 % assigned-unassigned nodes
            pot(:,assigned_labels) = 0;
        else
        end 
        pot(find(pot<0.01)) = 0.001; %  small potential of incompatible matches
        pot = pot - diag(diag(pot)) + 0.001*eye(size(pot,1));
        edge_pot(:,:,i) = pot;
    end
    
    clamped = zeros(nNodes,1);
    clamped(assigned_nodes) = assigned_labels;
    
    [nodeBel,edgeBel,logZ] = UGM_Infer_Conditional(node_pot,edge_pot,edgeStruct,clamped,@UGM_Infer_LBP);
    conserved_nodeBel(unassigned_nodes,:) = nodeBel(unassigned_nodes,:);
    [sort_nodeBel,nodeBel_sort_index] = sort(nodeBel,2,'descend');
    
    curr_labels = nodeBel_sort_index(:,1);
    [PAscore,LRscore,DVscore,geodistscore,totscore] = consistency_scores(nNodes,curr_labels,X,Y,Z,PA_matrix,LR_matrix,DV_matrix,geo_dist,geo_dist_r);
    PA_score(:,cnt) = PAscore;
    LR_score(:,cnt) = LRscore;
    DV_score(:,cnt) = DVscore;
    geodist_score(:,cnt) = geodistscore;
    tot_score(:,cnt) = totscore;
%     landmarkMatchScore = compare_labels_of_hidden_landmarks(curr_labels,rand_selection,landmark_to_neuron_map,landmark_names,thisimage_r,mu_r,Neuron_head,conserved_nodeBel);
%     landmark_match_score(:,cnt) = landmarkMatchScore;
    
    node_label = duplicate_labels(curr_labels,X,Y,Z,PA_matrix,LR_matrix,DV_matrix,geo_dist,geo_dist_r,img_1,mu_r,Neuron_head,lambda_geo,clamped_neurons);
    cnt = cnt + 1;
end

%%% save experiments results
disp('6. Saving prediction')
experiments = struct();
experiments(1).K = K;
experiments(1).lambda_PA = lambda_PA;
experiments(1).lambda_LR = lambda_LR;
experiments(1).lambda_DV = lambda_DV;
experiments(1).lambda_geo = lambda_geo;
experiments(1).lambda_angle = lambda_angle;
experiments(1).PA_score = PA_score;
experiments(1).LR_score = LR_score;
experiments(1).DV_score = DV_score;
experiments(1).geodist_score = geodist_score;
experiments(1).tot_score = tot_score;
%     experiments(1).landmark_match_score = landmark_match_score;
experiments(1).numLabelRemove = numLabelRemove;
experiments(1).loc_sigma = loc_sigma;

experiments(1).node_label = node_label;
%     experiments(1).mu_r = mu_r;
%     experiments(1).thisimage_r = thisimage_r;
experiments(1).Neuron_head = Neuron_head;
%     experiments(1).landmarks_used = rand_selection;
%     experiments(1).landmark_names = landmark_names;
%     experiments(1).landmark_to_neuron_map = landmark_to_neuron_map;
save(out_file,'experiments')
end

function TF = checkWeights(x)
   TF = false;
   if or(size(x,2) > 5,size(x,2) < 5) 
       error('weights must be 1-by-5 array');
   else
       TF = true;
   end
end
function TF = checkStrain(x)
    TF = false;
    validStrain = {'other','LandmarkStrain'};
    TF = any(validatestring(x,validStrain));
end
function TF = checkNodePotType(x)
    TF = false;
    validNodePotType = {'uniform','ap','reg','col'};
    TF = any(validatestring(x,validNodePotType));
end