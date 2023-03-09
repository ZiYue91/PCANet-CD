% ==== Demo =======
% Yue Zi, Fengying Xie, and Zhiguo Jiang, 
% "A Cloud Detection Method for Landsat 8 Images Based on PCANet" submitted to Remote Sensing. 

% Yue Zi [ziyue91@buaa.edu.cn]
% Please email me if you find bugs, or have suggestions or questions!
% ========================

clear all; close all; clc; 

addpath('.\Utils\DN2TOA');
addpath('.\Utils\SLIC');
addpath('.\Utils\PCANet');
addpath('.\Utils\PCANet\Utils');
addpath('.\Utils\PCANet\Liblinear');
addpath('.\Utils\CRF');

% Loading parameters of the trained PCANet and SVM
load('parameters.mat');

% Loading the Landsat 8 image and Converting DN into TOA reflectance
str='F:\Landsat8\Grass-Crops\LC81820302014180LGN00\LC81820302014180LGN00_MTL.txt';
Data=loadLandSat8(str);
output=ToR_LandSat8(Data,'TOARef');
clear Data;
output.TOARef{8}=imresize(output.TOARef{8},size(output.TOARef{1}));
data=cat(3,output.TOARef{:});
data(isnan(data))=0.0;
clear output;
[n m k]=size(data);

% Compositing false color image of Bands 6, 3 and 2   
Irgb=data(:,:,[6,3,2]);

% Superpixel Segmentation
img=uint8(255*Irgb);
superpixel_num=round(n/50)*round(m/50);
[labels, numlabels] = slicmex(img,superpixel_num,20);%numlabels is the same as number of superpixels
labels=labels+1;
cent=regionprops(labels,'Centroid');

% Calculating the brightness feature for each pixel
img1=mean(Irgb,3).*(min(Irgb,[],3)./(max(Irgb,[],3)+eps));
img2=zeros(n,m);
img2(img1<0.073)=-1;
img2(img1>0.176)=1;
clear Irgb img1;
        
% Calculating the brightness feature for each superpixel
count=zeros(numlabels,3);
for i=1:n
    for j=1:m
        count(labels(i,j),1)=count(labels(i,j),1)+img2(i,j);
        count(labels(i,j),2)=count(labels(i,j),2)+1;
    end
end
clear img2;
count(:,3)=count(:,1)./count(:,2);

% Extending the edge of the image
I1 = data(55:-1:1,55:-1:1,:);
I2 = data(55:-1:1,:,:);
I3 = data(55:-1:1,end:-1:end-54,:);
I4 = data(:,55:-1:1,:);
I5 = data(:,end:-1:end-54,:);
I6 = data(end:-1:end-54,55:-1:1,:);
I7 = data(end:-1:end-54,:,:);
I8 = data(end:-1:end-54,end:-1:end-54,:);
dst=[I1 I2 I3;I4 data I5;I6 I7 I8];
clear data I1 I2 I3 I4 I5 I6 I7 I8;

% Superpixel Coarse Classification
TestData9=cell(numlabels,1);
TestData5=cell(numlabels,1);
TestLabels=zeros(numlabels,1);
potential_index=zeros(numlabels,1);
index1=0;
im1=zeros(55,55,5);
for index=1:numlabels
    if count(index,3)<-0.7
       TestLabels(index)=0;
    elseif count(index,3)>0.7
        TestLabels(index)=1;
    else
        index1=index1+1;
        potential_index(index1)=index;
        x=round(cent(index).Centroid(1));
        y=round(cent(index).Centroid(2));
        x=x+55;
        y=y+55;
        im=dst(y-27:y+27,x-27:x+27,:);
        im1(:,:,1)=(im(:,:,3)-im(:,:,6))./(im(:,:,3)+im(:,:,6)+eps);
        im1(:,:,2)=(im(:,:,5)-im(:,:,4))./(im(:,:,5)+im(:,:,4)+eps);
        MeanVis=(im(:,:,2)+im(:,:,3)+im(:,:,4))/3;
        im1(:,:,3)=(abs(im(:,:,2)-MeanVis)+abs(im(:,:,3)-MeanVis)+abs(im(:,:,4)-MeanVis))./(MeanVis+eps);
        im1(:,:,4)=im(:,:,2)-0.5*im(:,:,4);
        im1(:,:,5)=im(:,:,5)./(im(:,:,6)+eps);
        im1(isnan(im1))=0.0;
        im1(isinf(im1))=0.0;
        TestData9{index1}=im;
        TestData5{index1}=im1;
    end
end
clear dst;
potential_index=potential_index(1:index1);
TestData9=TestData9(1:index1);
TestData5=TestData5(1:index1); 
        
% Identification of the Potential Cloud Superpixels
TestLabels1 = zeros(index1,1);
f=PCANet_FeaExt(TestData9(1),V9,PCANet);
ftest=sparse(2*length(f),index1);
n1=ceil(length(TestLabels1)/200);
for i=1:n1
    ftest(1:length(f),i:n1:end) = PCANet_FeaExt(TestData9(i:n1:end),V9,PCANet);
    ftest(length(f)+1:end,i:n1:end) = PCANet_FeaExt(TestData5(i:n1:end),V5,PCANet);
    for j=i:n1:length(TestData9)
        TestData9{j}=[];
        TestData5{j}=[];
    end
end

[xLabel_est1, accuracy, decision_values1] = predict(TestLabels1,ftest', models, '-q');
clear ftest;

decision_values1 =1./(1+exp(-decision_values1));
decision_values=TestLabels;
decision_values(potential_index)=decision_values1;
result_coarse=zeros(n,m);
for i=1:n
    for j=1:m
        result_coarse(i,j)=decision_values(labels(i,j));
    end
end

% Refinement with Fully Connected CRFs
classes = 2;
u=zeros(n,m,2);
u(:,:,1)=1-result_coarse;
u(:,:,2)=result_coarse;
u=-1*u;

u = permute(u, [2 1 3]);
u = reshape(u, size(img, 1)*size(img, 2), classes);
u = u';

tmpImg = reshape(img, [], 3);
tmpImg = tmpImg';
tmpImg = reshape(tmpImg, 3, size(img, 1), size(img, 2));
tmpImg = permute(tmpImg, [1 3 2]);
clear img labels result_coarse

sw = 1;
s = 1;
bw = 10;
bl = 300;
bc = 3;
[L, ~] = fullCRFinfer(single(u), uint8(tmpImg), s, s,sw, bl, bl, bc, bc,bc, bw, size(tmpImg, 2), size(tmpImg, 3), 20);
result_finer = (reshape(L, size(tmpImg, 2), size(tmpImg, 3)))';

% Saving cluod detection result
imwrite(double(result_finer),'result.tiff');

