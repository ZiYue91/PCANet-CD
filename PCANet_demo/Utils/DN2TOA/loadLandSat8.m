%%
% Copyright (c) 2014, Mohammad Abouali (maboualiedu@gmail.com)
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without 
% modification, are permitted provided that the following conditions are 
% met:
% 
%     * Redistributions of source code must retain the above copyright 
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright 
%       notice, this list of conditions and the following disclaimer in 
%       the documentation and/or other materials provided with the distribution
%       
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
% POSSIBILITY OF SUCH DAMAGE.

function LandSatData=loadLandSat8(metaFileName,bandList)
%% This function requires Mapping Toolbox; Checking if it exists
if (~license('checkout','map_toolbox'))
  error(['can not check out Mapping Toolbox. ' ...
         'Make sure you have this toolbox and you can check it out']);
end

%% This function requires parseLandSat8MetaData.m; Checking if it is available
if (exist('parseLandSat8MetaData.m','file')~=2)
  error(['can not access parseLandSat8MetaData.m ' ...
         'Make sure MATLAB can access this file. ' ...
         ' parseLandSat8MetaData.m can be downloaded from Mathworks File Exchange.' ...
         'http://www.mathworks.com/matlabcentral/fileexchange/48614-parselandsat8metadata-filename-']);
end

%% Checking input filename
validateattributes(metaFileName,{'char'},{'row'});

%% Checking inputBandList
if ( nargin<2 || isempty(bandList) )
  bandList=1:12;
else
  validateattributes(bandList,{'numeric'},{'vector'});
  if ( any((bandList-round(bandList))~=0) )
    error('bandList must contains only integer numbers.');
  end
  if ( any(bandList>12 | bandList<1) )
    error('bandList can contains only integer numbers between 1 and 12. (12th band refers to Band Quality)');
  end
end

%% loading the meta data
metaData=parseLandSat8MetaData(metaFileName);

%% Checking if it was a L1 Meta Data and required field exists
if (~isfield(metaData,'L1_METADATA_FILE'))
  error('The meta data file must be LandSat8 L1 Meta Data');
end

if (~isfield(metaData.L1_METADATA_FILE,'PRODUCT_METADATA'))
  error('It appears meta data is not complete.');
end

%% Now loading data
LandSatData.Band=cell(11,1);
LandSatData.BandInfo=cell(11,1);
LandSatData.BQA=[];
LandSatData.BQAInfo=[];
LandSatData.MetaData=metaData;

[folder,~,~]=fileparts(metaFileName);
for i=1:numel(bandList)
  bandNumber=bandList(i);
  if (bandNumber>=1 && bandNumber<=11)
    fileNameField=['FILE_NAME_BAND_' num2str(bandNumber)];
    if (~isfield(metaData.L1_METADATA_FILE.PRODUCT_METADATA,fileNameField))
      warning(['information about Band ' num2str(bandNumber) ' is missing. skipping this band']);
    else
      LandSatData.Band{bandNumber}=imread(fullfile(folder,metaData.L1_METADATA_FILE.PRODUCT_METADATA.(fileNameField)));
      LandSatData.BandInfo{bandNumber}=geotiffinfo(fullfile(folder,metaData.L1_METADATA_FILE.PRODUCT_METADATA.(fileNameField)));
    end
  elseif (bandNumber==12)
    fileNameField='FILE_NAME_BAND_QUALITY';
    if (~isfield(metaData.L1_METADATA_FILE.PRODUCT_METADATA,fileNameField))
      warning('information about Band quality is missing. skipping this band');
    else
      LandSatData.BQA=imread(fullfile(folder,metaData.L1_METADATA_FILE.PRODUCT_METADATA.(fileNameField)));
      LandSatData.BQAInfo=geotiffinfo(fullfile(folder,metaData.L1_METADATA_FILE.PRODUCT_METADATA.(fileNameField)));
    end  
  end
    
end
  
end