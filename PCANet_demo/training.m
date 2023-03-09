% ==== Demo =======
% Yue Zi, Fengying Xie, and Zhiguo Jiang, 
% "A Cloud Detection Method for Landsat 8 Images Based on PCANet" submitted to Remote Sensing. 

% Yue Zi [ziyue91@buaa.edu.cn]
% Please email me if you find bugs, or have suggestions or questions!
% ========================

clear all; close all; clc; 

addpath('.\Utils\PCANet');
addpath('.\Utils\PCANet\Utils');
addpath('.\Utils\PCANet\Liblinear');

% Loading 9-dimensional TOA reflectance data
load('.\Traindata\traindata9.mat');

% Calculating 5-dimensional spectral feature data
TrainData5=cell(length(TrainLabels),1);
im1=zeros(55,55,5);
for i=1:length(TrainLabels)
    im=TrainData9{i};
    im1(:,:,1)=(im(:,:,3)-im(:,:,6))./(im(:,:,3)+im(:,:,6)+eps);
    im1(:,:,2)=(im(:,:,5)-im(:,:,4))./(im(:,:,5)+im(:,:,4)+eps);
    MeanVis=(im(:,:,2)+im(:,:,3)+im(:,:,4))/3;
    im1(:,:,3)=(abs(im(:,:,2)-MeanVis)+abs(im(:,:,3)-MeanVis)+abs(im(:,:,4)-MeanVis))./MeanVis;
    im1(:,:,4)=im(:,:,2)-0.5*im(:,:,4);
    im1(:,:,5)=im(:,:,5)./(im(:,:,6)+eps);
    im1(isnan(im1))=0.0;
    im1(isinf(im1))=0.0;
    TrainData5{i}=im1;
end

% Setting the parameters of PCANet
PCANet.NumStages = 2;
PCANet.PatchSize = [7 7];
PCANet.NumFilters = [8 8];
PCANet.HistBlockSize = [7 7]; 
PCANet.BlkOverLapRatio = 0;
PCANet.Pyramid = [];

% Training the double-branch PCANet
fprintf('\n ====== Double-branch PCANet Training ======= \n')
[ftrain V9 BlkIdx] = PCANet_train(TrainData9,PCANet,0); 
[ftrain V5 BlkIdx] = PCANet_train(TrainData5,PCANet,0); 

% Extracting features
f=PCANet_FeaExt(TrainData9(1),V9,PCANet);
ftrain=sparse(2*length(f),length(TrainLabels));
n=ceil(length(TrainLabels)/200);
for i=1:n
    ftrain(1:length(f),i:n:end) = PCANet_FeaExt(TrainData9(i:n:end),V9,PCANet);
    ftrain(length(f)+1:end,i:n:end) = PCANet_FeaExt(TrainData5(i:n:end),V5,PCANet);
    for jj=i:n:length(TrainLabels)
        TrainData9{jj}=[];
        TrainData5{jj}=[];
    end
end

% Training linear SVM classifier
fprintf('\n ====== Training Linear SVM Classifier ======= \n')
models = train(TrainLabels, ftrain', '-s 1');
clear ftrain;
save('parameters.mat','models','V9','V5','PCANet');

