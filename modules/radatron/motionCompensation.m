function [rangeFFTOut_compensated] = motionCompensation(rangeFFTOut, CFAR_CASO_overlapAntenna_ID)    
    
    rangeFFTOut_virtualAnt = reshape(rangeFFTOut,size(rangeFFTOut,1), size(rangeFFTOut,2), []); % 512 by 64 by 192

    rangeFFTOut_diff = rangeFFTOut_virtualAnt(:,:,CFAR_CASO_overlapAntenna_ID(:,2))./rangeFFTOut_virtualAnt(:,:,CFAR_CASO_overlapAntenna_ID(:,1));
    rangeFFTOut_diff = reshape(rangeFFTOut_diff(:,24:40,:),size(rangeFFTOut_diff,1),[]);         
    motionPhase = median(angle(rangeFFTOut_diff),2);
    
    %     figure; plot(motionPhase);
    motionPhase([1:80,490:end]) = 0;

    motionPhase_compensate = reshape(-motionPhase.*[1:12],512,1,1,12);
    rangeFFTOut_compensated = rangeFFTOut .* repmat(exp(1j*motionPhase_compensate),[1,64,16,1]);
end