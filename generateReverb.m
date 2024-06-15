function [wetReverb] = generateReverb(cleanSignal,outputSampleRate,preDelay,highCut,diffusion,decay,freqDamp,wetDry)
% the function returns reverb of the signal based on parameters 

reverb = reverberator("PreDelay",preDelay,"HighCutFrequency",highCut,"Diffusion",...
            diffusion,"DecayFactor",decay,"HighFrequencyDamping",freqDamp,"WetDryMix",wetDry,"SampleRate",outputSampleRate);
mixWithOnlyReverb = reverb(cleanSignal);
wetReverb = mean(mixWithOnlyReverb,2); % returns the reverb in mono


end