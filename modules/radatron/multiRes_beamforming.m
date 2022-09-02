%% Beamforming - single TX        
numRXAnts = size(rangeFFTOut,3);

beamformIn = reshape(permute(rangeFFTOut(:,:,:,1:antAryTopol.numTXAnts),[1,2,4,3]),[],numRXAnts);

virArray1D = phased.ConformalArray('ElementNormal',[zeros(1,numRXAnts);zeros(1,numRXAnts)], ...
'ElementPosition',[zeros(1,numRXAnts);(max(antAryTopol.D_RX)-antAryTopol.D_RX)*antAryTopol.lambda/2;zeros(1,numRXAnts)]);

beamformOut = PhaseShift_beamforming_1D(virArray1D, antAryTopol, BFPropty, beamformIn, 0);

beamformOuts.LowRes = beamformOut(:,:,1);

%% Beamforming - single chip 
numRXAnts = 8;
        
beamformIn = reshape(permute(flip(rangeFFTOut(:,:,9:16,1:antAryTopol.numTXAnts),3),[1,2,4,3]),[],numRXAnts);

virArray1D = phased.ULA('NumElements',numRXAnts,'ElementSpacing',antAryTopol.lambda/2);

beamformOut = PhaseShift_beamforming_1D(virArray1D, antAryTopol, BFPropty, beamformIn, 0);

beamformOuts.SingleChip = beamformOut(:,:,1);

%% Beamforming - HiRes
rangeFFTOut_virtualArray = zeros(size(rangeFFTOut_nonOverlap,1),BFPropty.num_DopplerBins,7*86); 
rangeFFTOut_virtualArray(:,:,antAryTopol.DIdx_nonOverlap_sort) = rangeFFTOut_nonOverlap; % find virtual array elements
rangeFFTOut_virtualArray2D = reshape(rangeFFTOut_virtualArray,[size(rangeFFTOut_nonOverlap,1),BFPropty.num_DopplerBins,7,86]);
rangeFFTOut_virtualArray1D = squeeze(rangeFFTOut_virtualArray2D(:,:,1,:)); % Horizontal Array

beamformIn = reshape(rangeFFTOut_virtualArray1D,[],86);

virArray1D = phased.ULA('NumElements',antAryTopol.numTXAnts_full1D,'ElementSpacing',antAryTopol.lambda/2);

beamformOut = PhaseShift_beamforming_1D(virArray1D, antAryTopol, BFPropty, beamformIn, 1);

beamformOuts.HighRes = beamformOut;

%% Beamforming - 9TX No Motion induced phase compensation
rangeFFTOut_nonOverlap_noFix = reshape(rangeFFTOut,size(rangeFFTOut,1), ...
    size(rangeFFTOut,2), size(rangeFFTOut,3)*size(rangeFFTOut,4)); % 512 by 64 by 192
rangeFFTOut_nonOverlap_noFix = rangeFFTOut_nonOverlap_noFix(:,:,antAryTopol.nonOverlap_Antenna_ID);

rangeFFTOut_virtualArray = zeros(size(rangeFFTOut_nonOverlap_noFix,1),BFPropty.num_DopplerBins,7*86); 
rangeFFTOut_virtualArray(:,:,antAryTopol.DIdx_nonOverlap_sort) = rangeFFTOut_nonOverlap_noFix; % find virtual array elements
rangeFFTOut_virtualArray2D = reshape(rangeFFTOut_virtualArray,[size(rangeFFTOut_nonOverlap_noFix,1),BFPropty.num_DopplerBins,7,86]);
rangeFFTOut_virtualArray1D = squeeze(rangeFFTOut_virtualArray2D(:,:,1,:)); % Horizontal Array

beamformIn = reshape(rangeFFTOut_virtualArray1D,[],86);

virArray1D = phased.ULA('NumElements',antAryTopol.numTXAnts_full1D,'ElementSpacing',antAryTopol.lambda/2);

beamformOut = PhaseShift_beamforming_1D(virArray1D, antAryTopol, BFPropty, beamformIn, 1);

beamformOuts.NoFix = beamformOut;

%%
function beamformOut = PhaseShift_beamforming_1D(virArray1D, antAryTopol, BFPropty, beamformIn, HiRes_flag)
    PhaseShift_beamformer = phased.PhaseShiftBeamformer('SensorArray',virArray1D,...
        'OperatingFrequency',BFPropty.centerFreq, 'PropagationSpeed',physconst('LightSpeed'), ...
        'DirectionSource','Input port');

    beamformOut = PhaseShift_beamformer(beamformIn,[reshape(BFPropty.azimuthAxisDeg,1,[]);zeros(1,BFPropty.num_azimuthBins)]);

    if HiRes_flag
        beamformOut = reshape(beamformOut,BFPropty.num_rangeBins,BFPropty.num_DopplerBins,BFPropty.num_azimuthBins);
        beamformOut = squeeze(beamformOut);
    else
        beamformOut = reshape(beamformOut,BFPropty.num_rangeBins,BFPropty.num_DopplerBins,antAryTopol.numTXAnts,BFPropty.num_azimuthBins);
        beamformOut = squeeze(permute(beamformOut,[1,2,4,3]));
    end
end