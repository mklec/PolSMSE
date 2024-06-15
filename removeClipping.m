function [signalOut] = removeClipping(signal)
% if clipping occurs, remove it. Very simple method of preventing the file
% from being overclipped. It works as hard limiter.

signalOut = signal;

positiveClipValue = 0.999; 
badIndexes = signal >= positiveClipValue;
signalOut(badIndexes) = positiveClipValue;

negativeClipValue = -0.999; 
badIndexes = signal <= negativeClipValue;
signalOut(badIndexes) = negativeClipValue;


end

