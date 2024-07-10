function [mix,mixedSignal,mixedNoise,factor] = mixSignals(signal,noise,ratio)
% [mix,mixedSignal,mixedNoise,factor] = mixSignals(signal,noise,ratio) returns a noisy
% version of the signal, mix. The mixedSignal signal has been mixed with
% mixedNoise at the specified ratio in dB.
% smaller ratio than more noise in the mix

signalNorm = norm(signal);
noiseNorm = norm(noise);

goalNoiseNorm = signalNorm/(10^(ratio/20));
factor = goalNoiseNorm/noiseNorm;

mixedNoise = noise.*factor;
mix = signal + mixedNoise;
mixedSignal = signal;

end