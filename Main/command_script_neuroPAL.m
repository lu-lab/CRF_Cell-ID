% command script to run neuron ID. 
% Check the following variables are set correctly before running
% datadriven atlas: whichatlas
% groundtruth labels: markernamesfile

%checklist before running
% check atlas name
% check node potential mode 'col' for color incorporated

clear
clc
addpath('Main')

tableofaccuracy= zeros(1,5);

csv_files_all= []; 

% folder_direc= '/Users/hyunjee/Dropbox (GaTech)/Whole-brain codes/CRF_Cell_ID-master/Datasets/aligned_worms_Kato/worms_by_group/files_after_removal/0';
% csv_files_full = dir(fullfile(folder_direc,'*.csv'));
% csv_files_dataset = {csv_files_full.folder; csv_files_full.name};
% csv_files_all = [csv_files_all csv_files_dataset];

% folder_direc= '/Users/hyunjee/Dropbox (GaTech)/Whole-brain codes/CRF_Cell_ID-master/Datasets/aligned_worms_Kato/worms_by_group/files_after_removal/1';
% csv_files_full = dir(fullfile(folder_direc,'*.csv'));
% csv_files_dataset = {csv_files_full.folder; csv_files_full.name};
% csv_files_all = [csv_files_all csv_files_dataset];
% 
% folder_direc= '/Users/hyunjee/Dropbox (GaTech)/Whole-brain codes/CRF_Cell_ID-master/Datasets/aligned_worms_Kato/worms_by_group/files_after_removal/2';
% csv_files_full = dir(fullfile(folder_direc,'*.csv'));
% csv_files_dataset = {csv_files_full.folder; csv_files_full.name};
% csv_files_all = [csv_files_all csv_files_dataset];
% 
% folder_direc= '/Users/hyunjee/Dropbox (GaTech)/Whole-brain codes/CRF_Cell_ID-master/Datasets/aligned_worms_Kato/worms_by_group/files_after_removal/3';
% csv_files_full = dir(fullfile(folder_direc,'*.csv'));
% csv_files_dataset = {csv_files_full.folder; csv_files_full.name};
% csv_files_all = [csv_files_all csv_files_dataset];

folder_direc= '/Users/hyunjee/Dropbox (GaTech)/Whole-brain codes/CRF_Cell_ID-master/Datasets/aligned_worms_Kato/worms_by_group/files_after_removal/4';
csv_files_full = dir(fullfile(folder_direc,'*.csv'));
csv_files_dataset = {csv_files_full.folder; csv_files_full.name};
csv_files_all = [csv_files_all csv_files_dataset];

% folder_direc= '/Users/hyunjee/Dropbox (GaTech)/Whole-brain codes/CRF_Cell_ID-master/Datasets/aligned_worms_Kato/wo_color_correction/0';
% csv_files_full = dir(fullfile(folder_direc,'*.csv'));
% csv_files_dataset = {csv_files_full.folder; csv_files_full.name};
% csv_files_all = [csv_files_all csv_files_dataset];
% 
% folder_direc= '/Users/hyunjee/Dropbox (GaTech)/Whole-brain codes/CRF_Cell_ID-master/Datasets/aligned_worms_Kato/wo_color_correction/1';
% csv_files_full = dir(fullfile(folder_direc,'*.csv'));
% csv_files_dataset = {csv_files_full.folder; csv_files_full.name};
% csv_files_all = [csv_files_all csv_files_dataset];
% 
% folder_direc= '/Users/hyunjee/Dropbox (GaTech)/Whole-brain codes/CRF_Cell_ID-master/Datasets/aligned_worms_Kato/wo_color_correction/2';
% csv_files_full = dir(fullfile(folder_direc,'*.csv'));
% csv_files_dataset = {csv_files_full.folder; csv_files_full.name};
% csv_files_all = [csv_files_all csv_files_dataset];
% 
% folder_direc= '/Users/hyunjee/Dropbox (GaTech)/Whole-brain codes/CRF_Cell_ID-master/Datasets/aligned_worms_Kato/wo_color_correction/3';
% csv_files_full = dir(fullfile(folder_direc,'*.csv'));
% csv_files_dataset = {csv_files_full.folder; csv_files_full.name};
% csv_files_all = [csv_files_all csv_files_dataset];
% 
% folder_direc= '/Users/hyunjee/Dropbox (GaTech)/Whole-brain codes/CRF_Cell_ID-master/Datasets/aligned_worms_Kato/wo_color_correction/4';
% csv_files_full = dir(fullfile(folder_direc,'*.csv'));
% csv_files_dataset = {csv_files_full.folder; csv_files_full.name};
% csv_files_all = [csv_files_all csv_files_dataset];

for j= 1:size (csv_files_all,2)

%%% Reading data

csv_file_direc= [char(csv_files_all(1,j)) '/' char(csv_files_all(2,j))];
raw_data= readtable(csv_file_direc);

X_rot= -table2array(raw_data(:,9));
Y_rot= -table2array(raw_data(:,8));
Z_rot= -table2array(raw_data(:,10));
mu_r= [X_rot Y_rot Z_rot];
neuron_list= table2array(raw_data(:,14));
color_data= table2array(raw_data(:,11:13));


save([folder_direc erase(char(csv_files_all(2,j)),".csv")], 'mu_r', 'neuron_list', 'color_data');

%%% CRF_ID

howmanyruns=1; % specify the number of runs

coord_data_dir=[folder_direc erase(char(csv_files_all(2,j)),".csv") ];
CRF_result_dir=[folder_direc '/CRF_result_original_Lu_cc'];

atlas_dir= '/Users/hyunjee/Dropbox (GaTech)/Whole-brain codes/CRF_Cell_ID-master/utils/atlas_o0123.mat';
%atlas_dir= '/Users/hyunjee/Dropbox (GaTech)/Whole-brain codes/CRF_Cell_ID-master/utils/data_neuron_relationship_annotation_updated.mat';


for m= 1:howmanyruns

    annotation_CRF_landmark_neuroPAL(coord_data_dir, CRF_result_dir,'col',atlas_dir,'weights',[0,0,0,0,1]);
    
    load(CRF_result_dir);

predictionlist= cell(size(experiments.node_label,1),5);

for l=find(experiments.node_label(:,1) ~= -1)'
predictionlist{l,1}= experiments.Neuron_head{experiments.node_label(l,1),1};
predictionlist{l,2}= experiments.Neuron_head{experiments.node_label(l,2),1};
predictionlist{l,3}= experiments.Neuron_head{experiments.node_label(l,3),1};
predictionlist{l,4}= experiments.Neuron_head{experiments.node_label(l,4),1};
predictionlist{l,5}= experiments.Neuron_head{experiments.node_label(l,5),1};
end

neuronprediction= string(predictionlist);
end

% [orderedlist,~,ind]= unique(neuronprediction);
% indstoredprediction= reshape(ind,size(neuronprediction));
% [IDpercent,i]=sort(histc(indstoredprediction,unique(indstoredprediction),2),2);
% top1prediction= orderedlist(i(:,end));


%Accuracy Analysis (worm accuracy and neuron accuracy)
load(coord_data_dir)

% Make a list of the answer key
neuronkey= neuron_list;

% Save the predictions
excel_file_name= 'CRF_ID_predictions_multilab+color_corrected.xlsx';
table= [{'GT' 'Top1' 'Top2' 'Top3' 'Top4' 'Top5'}; [neuron_list predictionlist]];
writecell(table,excel_file_name,'Sheet', char(csv_files_all(2,j)),'Range','A1')

%calcualte accuracy
top1matchcount=0;
top2matchcount=0;
top3matchcount=0;
top4matchcount=0;
top5matchcount=0;
for k=1:size(experiments.node_label,1)
        if neuronkey(k,1) == neuronprediction(k,1)
           top1matchcount= top1matchcount+1;
        end
        if sum(neuronkey(k,1) == neuronprediction(k,1:2))>0
           top2matchcount= top2matchcount+1;
        end
        if sum(neuronkey(k,1) == neuronprediction(k,1:3))>0
           top3matchcount= top3matchcount+1;
        end
        if sum(neuronkey(k,1) == neuronprediction(k,1:4))>0
           top4matchcount= top4matchcount+1;
        end
        if sum(neuronkey(k,1) == neuronprediction(k,1:5))>0
           top5matchcount= top5matchcount+1;
        end
end
numcompared= size(experiments.node_label,1) - sum(neuronkey(1:size(experiments.node_label,1))=="");
tableofaccuracy(j,:)= [top1matchcount/numcompared top2matchcount/numcompared top3matchcount/numcompared top4matchcount/numcompared top5matchcount/numcompared];
end

