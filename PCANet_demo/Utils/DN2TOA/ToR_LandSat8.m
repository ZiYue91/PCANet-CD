%%
% Copyright (c) 2015, Mohammad Abouali (maboualiedu@gmail.com)
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
%     * Once this code is used please cite it as:
%          Abouali, M., "LandSat8 Radiance, Reflectance, Brightness Temperature, and Atmospheric Correction", Matlab File Exchange, FILE ID #50636, 2015.
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

function output=ToR_LandSat8(Data,operationList,bandList)
if (ischar(operationList))
  validateattributes(operationList,{'char'},{'row'});
  operationList={operationList};
else
  validateattributes(operationList,{'cell'},{'vector'});
end

% NOTE:
%   - Data must be loaded with laodLandSat8().
for opID=1:numel(operationList)
  switch lower(operationList{opID})
    case 'toarad'
      disp('Calculating Top Of Atmosphere (TOA) Radiance ...')
      % TOARad: Top Of Atmosphere Radiance    
      % Checking bandList
      if (nargin<3 || isempty(bandList))
        bandList=1:11;
      end

      % making sure band numbers are not repeated.
      opBandList=unique(bandList);

      % checking if the requested bandNumber is loaded.
      bandIsLoaded=cellfun(@(x) ~isempty(x),Data.Band);
      bandIsLoaded=bandIsLoaded(opBandList);
      if (all(~bandIsLoaded))
        error('None of the requested bands are laoded')
      elseif (any(~bandIsLoaded))
        disp('The following Bands are not loaded:')
        disp(opBandList(~bandIsLoaded))
        disp('These bands are ignored.')
      end
      opBandList=opBandList(bandIsLoaded);

      % performing required calculation
      output.TOARad_bandList=opBandList;
      output.TOARad=cell(numel(opBandList),1);    
      for i=1:numel(opBandList)
        m=Data.MetaData.L1_METADATA_FILE.RADIOMETRIC_RESCALING.(['RADIANCE_MULT_BAND_' num2str(opBandList(i))]);
        b=Data.MetaData.L1_METADATA_FILE.RADIOMETRIC_RESCALING.(['RADIANCE_ADD_BAND_' num2str(opBandList(i))]);
        tmpOutput=m*double(Data.Band{opBandList(i)})+b;
        tmpOutput(Data.Band{opBandList(i)}==0)=NaN;
        output.TOARad{i}=tmpOutput;
      end
    case 'toaref'
      disp('Calculating Top Of Atmosphere (TOA) Reflectance ...')
      % TOARef: Top Of Atmosphere Reflectance    
      % Checking bandList
      if (nargin<3 || isempty(bandList))
        bandList=1:9;
      end

      % making sure band numbers are not repeated.
      opBandList=unique(bandList);

      % Removing any band greater than 9
      opBandList=opBandList(opBandList<=9);

      % checking if the requested bandNumber is loaded.
      bandIsLoaded=cellfun(@(x) ~isempty(x),Data.Band);
      bandIsLoaded=bandIsLoaded(opBandList);
      if (all(~bandIsLoaded))
        error('None of the requested bands are laoded')
      elseif (any(~bandIsLoaded))
        disp('The following Bands are not loaded:')
        disp(opBandList(~bandIsLoaded))
        disp('These bands are ignored.')
      end
      opBandList=opBandList(bandIsLoaded);

      % performing required calculation
      output.TOARef_bandList=opBandList;
      output.TOARef=cell(numel(opBandList),1);    
      for i=1:numel(opBandList)
        m=Data.MetaData.L1_METADATA_FILE.RADIOMETRIC_RESCALING.(['REFLECTANCE_MULT_BAND_' num2str(opBandList(i))]);
        b=Data.MetaData.L1_METADATA_FILE.RADIOMETRIC_RESCALING.(['REFLECTANCE_ADD_BAND_' num2str(opBandList(i))]);
        s=sind(Data.MetaData.L1_METADATA_FILE.IMAGE_ATTRIBUTES.SUN_ELEVATION);
        tmpOutput=(m* double(Data.Band{opBandList(i)})+b)*(1./s);
        tmpOutput(Data.Band{opBandList(i)}==0)=NaN;
        tmpOutput(tmpOutput<0.0)=0.0;
        tmpOutput(tmpOutput>1.0)=1.0;
        output.TOARef{i}=tmpOutput;
      end
    case 'satbt'
      disp('Calculating At Satellite Brightness Temperature ...')
      % SatBT: at Satellite Brightness Temperature
      % Checking bandList
      if (nargin<3 || isempty(bandList))
        bandList=10:11;
      end

      % making sure band numbers are not repeated.
      opBandList=unique(bandList);

      % Removing any band other than 10 and 11
      opBandList=[any(opBandList==10)*10 any(opBandList==11)*11];

      % checking if the requested bandNumber is loaded.
      bandIsLoaded=cellfun(@(x) ~isempty(x),Data.Band);
      bandIsLoaded=bandIsLoaded(opBandList);
      if (all(~bandIsLoaded))
        error('None of the requested bands are laoded')
      elseif (any(~bandIsLoaded))
        disp('The following Bands are not loaded:')
        disp(opBandList(~bandIsLoaded))
        disp('These bands are ignored.')
      end
      opBandList=opBandList(bandIsLoaded);

      % performing required calculation
      output.SatBT_bandList=opBandList;
      output.SatBT=cell(numel(opBandList),1);    
      for i=1:numel(opBandList)
        m=Data.MetaData.L1_METADATA_FILE.RADIOMETRIC_RESCALING.(['RADIANCE_MULT_BAND_' num2str(opBandList(i))]);
        b=Data.MetaData.L1_METADATA_FILE.RADIOMETRIC_RESCALING.(['RADIANCE_ADD_BAND_' num2str(opBandList(i))]);
        K1=Data.MetaData.L1_METADATA_FILE.TIRS_THERMAL_CONSTANTS.(['K1_CONSTANT_BAND_' num2str(opBandList(i))]);
        K2=Data.MetaData.L1_METADATA_FILE.TIRS_THERMAL_CONSTANTS.(['K2_CONSTANT_BAND_' num2str(opBandList(i))]);
        tmpOutput=m*double(Data.Band{opBandList(i)})+b;
        tmpOutput=K2./ log(K1./tmpOutput +1.0 );
        tmpOutput(Data.Band{opBandList(i)}==0)=NaN;
        output.SatBT{i}=tmpOutput;
      end
    case 'dos1'
      disp('Performing Dark-Object Subtraction 1 (DOS1) ...');
      % DOS1: Dark-Object Subtraction 1
      % Checking bandList
      if (nargin<3 || isempty(bandList))
        bandList=1:9;
      end

      % Removing any band greater than 9
      opBandList=bandList(bandList<=9);

      % checking if the requested bandNumber is loaded.
      bandIsLoaded=cellfun(@(x) ~isempty(x),Data.Band);
      bandIsLoaded=bandIsLoaded(opBandList);
      if (all(~bandIsLoaded))
        error('None of the requested bands are laoded')
      elseif (any(~bandIsLoaded))
        disp('The following Bands are not loaded:')
        disp(opBandList(~bandIsLoaded))
        disp('These bands are ignored.')
      end
      opBandList=opBandList(bandIsLoaded);

      % performing required calculation
      output.SurfaceRef_DOS1_bandList=opBandList;
      output.SurfaceRef_DOS1=cell(numel(opBandList),1);  
      for i=1:numel(opBandList)
        d=Data.MetaData.L1_METADATA_FILE.IMAGE_ATTRIBUTES.EARTH_SUN_DISTANCE;
        e=Data.MetaData.L1_METADATA_FILE.IMAGE_ATTRIBUTES.SUN_ELEVATION;
        darkObject_prctile=0.01;
        sun_prct=1;
        TAUv = 1.0;
        TAUz = 1.0;
        Esky = 0.0;

        Esun=(pi * d.^2) .* ...
             Data.MetaData.L1_METADATA_FILE.MIN_MAX_RADIANCE.(['RADIANCE_MAXIMUM_BAND_' num2str(opBandList(i))])./ ...
             Data.MetaData.L1_METADATA_FILE.MIN_MAX_REFLECTANCE.(['REFLECTANCE_MAXIMUM_BAND_' num2str(opBandList(i))]);
        Sun_Radiance = TAUv * (Esun * sind(e) * TAUz + Esky) / (pi * d.^2);

        m=Data.MetaData.L1_METADATA_FILE.RADIOMETRIC_RESCALING.(['RADIANCE_MULT_BAND_' num2str(opBandList(i))]);
        b=Data.MetaData.L1_METADATA_FILE.RADIOMETRIC_RESCALING.(['RADIANCE_ADD_BAND_' num2str(opBandList(i))]);
        mask= (Data.Band{opBandList(i)}==0);
        AtSensorRadiance=m*double(Data.Band{opBandList(i)})+b;
        radiance_dark=m*double(getDarkDN(Data.Band{opBandList(i)},darkObject_prctile))+b;
        LHaze=radiance_dark-sun_prct*Sun_Radiance/100;

        radiance=AtSensorRadiance-LHaze;
        reflectance=radiance./Sun_Radiance;
        reflectance(mask)=NaN;
        reflectance(reflectance<0)=0.0;
        reflectance(reflectance>1)=1.0;
        output.SurfaceRef_DOS1{i}=reflectance;
      end
    case {'dos2','cost'}
      disp('Performing Dark-Object Subtraction 2 (DOS2) (also known as COST) ...')
      % DOS2: Dark-Object Subtraction 2
      % Checking bandList
      if (nargin<3 || isempty(bandList))
        bandList=1:9;
      end

      % Removing any band greater than 9
      opBandList=bandList(bandList<=9);

      % checking if the requested bandNumber is loaded.
      bandIsLoaded=cellfun(@(x) ~isempty(x),Data.Band);
      bandIsLoaded=bandIsLoaded(opBandList);
      if (all(~bandIsLoaded))
        error('None of the requested bands are laoded')
      elseif (any(~bandIsLoaded))
        disp('The following Bands are not loaded:')
        disp(opBandList(~bandIsLoaded))
        disp('These bands are ignored.')
      end
      opBandList=opBandList(bandIsLoaded);

      % performing required calculation
      output.SurfaceRef_DOS2_COST_bandList=opBandList;
      output.SurfaceRef_DOS2_COST=cell(numel(opBandList),1); 
      for i=1:numel(opBandList)
        d=Data.MetaData.L1_METADATA_FILE.IMAGE_ATTRIBUTES.EARTH_SUN_DISTANCE;
        e=Data.MetaData.L1_METADATA_FILE.IMAGE_ATTRIBUTES.SUN_ELEVATION;
        darkObject_prctile=0.01;
        sun_prct=1;
        TAUv = 1.0;
        Esky = 0.0;

        if ( opBandList(i)==6 || ...
             opBandList(i)==7 || ...
             opBandList(i)==9)
             TAUz=1.0;
        else
          TAUz=sind(e);
        end

        Esun=(pi * d.^2) .* ...
             Data.MetaData.L1_METADATA_FILE.MIN_MAX_RADIANCE.(['RADIANCE_MAXIMUM_BAND_' num2str(opBandList(i))])./ ...
             Data.MetaData.L1_METADATA_FILE.MIN_MAX_REFLECTANCE.(['REFLECTANCE_MAXIMUM_BAND_' num2str(opBandList(i))]);      
        Sun_Radiance = TAUv * (Esun * sind(e) * TAUz + Esky) / (pi * d.^2);

        m=Data.MetaData.L1_METADATA_FILE.RADIOMETRIC_RESCALING.(['RADIANCE_MULT_BAND_' num2str(opBandList(i))]);
        b=Data.MetaData.L1_METADATA_FILE.RADIOMETRIC_RESCALING.(['RADIANCE_ADD_BAND_' num2str(opBandList(i))]);
        mask= (Data.Band{opBandList(i)}==0);
        AtSensorRadiance=m*double(Data.Band{opBandList(i)})+b;
        radiance_dark=m*double(getDarkDN(Data.Band{opBandList(i)},darkObject_prctile))+b;
        LHaze=radiance_dark-sun_prct*Sun_Radiance/100;

        radiance=AtSensorRadiance-LHaze;
        reflectance=radiance./Sun_Radiance;
        reflectance(mask)=NaN;
        reflectance(reflectance<0.0)=0.0;
        reflectance(reflectance>1.0)=1.0;
        output.SurfaceRef_DOS2_COST{i}=reflectance;
      end
    otherwise
      error(['ToR_LandSat8: operation not recognized. ' ...
             'Supported operations are TOARad, TOARef, SatBT. ']);
  end
end
end
