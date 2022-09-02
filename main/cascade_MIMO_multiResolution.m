% cascade_MIMO_multiResolution.m
%
% Top level main test chain to process the raw ADC data. The processing
% chain including adc data calibration module, range FFT module, DopplerFFT
% module, CFAR module, DOA module. Each module is first initialized before
% actually used in the chain.

close all
clear
clc

addpath('../');
add_paths;

dayIdx = 1;
dataPath.root = ['../../radatron_dataset/day',num2str(dayIdx)];
    
%% 
pathGenParaFile = './input/dataCollection_param.m';
run(pathGenParaFile);

dataFolder_calib = '../main/input/calibrateResults_radatron.mat';

% Processing Parameters
run('processing_param');

% Load TI modules
calibrationObj = calibrationCascade('pfile', pathGenParaFile, 'calibrationfilePath', dataFolder_calib);

%%
for expIdx = 1
    dataPath.rawData = [dataPath.root,'/rawData/exp',num2str(expIdx)];

    % Get Unique File Idxs in the "dataPath.rawData"   
    [fileIdx_unique] = getUniqueFileIdx(dataPath.rawData);
    
    for i_file = 1:(length(fileIdx_unique))
        
        fileIdx = str2double(fileIdx_unique{i_file});

        % Get File Names for the Master, Slave1, Slave2, Slave3   
        [fileNameStruct]= getBinFileNames_withIdx(dataPath.rawData, fileIdx_unique{i_file});        
       
        %pass the Data File to the calibration Object
        calibrationObj.binfilePath = fileNameStruct;
        
        detection_results = [];  
        
        % Get Valid Number of Frames 
        [numValidFrames dataFileSize] = getValidNumFrames(fullfile(dataPath.rawData, fileNameStruct.masterIdxFile));
        %intentionally skip the first frame due to TDA2 

        for frameIdx = 2:1:numValidFrames %numFrames_toRun
            %read and calibrate raw ADC data            
            calibrationObj.frameIdx = frameIdx;
%             frameCountGlobal = frameCountGlobal+1
            adcData = datapath(calibrationObj);
            
            adcData = adcData/2^15; % adc sample normalize

            % RX Channel re-ordering
            adcData = adcData(:,:,calibrationObj.RxForMIMOProcess,:);            
            
            % DC offset compensation
            for ka = 1:numRxToEnable
                inputMat = squeeze(adcData(:,:,ka,:));
                inputMat = bsxfun(@minus, inputMat, mean(inputMat));
                adcData(:,:,ka,:) = inputMat;
            end
            
            if mod(frameIdx, 10)==1
                fprintf('Processing %3d frame...\n', frameIdx);
            end
            
            %% Range FFT
            rangeFFTOut = fft(adcData,[],1);
                        
            %% Motion induced phase compensation
            rangeFFTOut_compensated = motionCompensation(rangeFFTOut, CFAR_CASO_overlapAntenna_ID);
            
            %% Reduce # of chip loops
            rangeFFTOut = rangeFFTOut(:,32,:,:);
            rangeFFTOut_compensated = rangeFFTOut_compensated(:,32,:,:);
            
            %% Beamforming - Multi-Resolution
            rangeFFTOut_nonOverlap = reshape(rangeFFTOut_compensated,numADCSample, []); % 512 by 192
            rangeFFTOut_nonOverlap = rangeFFTOut_nonOverlap(:,nonOverlap_Antenna_ID);
            run('multiRes_beamforming');

            %% Save Heatmaps
            heatmap_types = fieldnames(beamformOuts);   
            fileName = sprintf('radar_day%d_exp%d_file%d_frm%d.mat',dayIdx,expIdx,fileIdx,frameIdx);
            for i = 1:numel(heatmap_types)
                fieldName = char(heatmap_types(i));

                dataPath.(fieldName) = [dataPath.root,'/heatmap_',fieldName,'/',fileName];
                heatmap = abs(beamformOuts.(fieldName));
                
                save(dataPath.(fieldName),'heatmap');
            end
        end 
    end
end
