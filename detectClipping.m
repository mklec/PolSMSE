function [clippingExists] = detectClipping(signal)
% if clipping occurs it returns 1

clippingExists = 0;

positiveClipValue = 0.9999; 
badIndexes = signal >= positiveClipValue;

if(sum(badIndexes)>0)
    clippingExists = 1;
end

negativeClipValue = -0.9999; 
badIndexes = signal <= negativeClipValue;
if(sum(badIndexes)>0)
    clippingExists = 1;
end


end

