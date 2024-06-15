% ######################################################################
% The script for generating simulated polish speech with noise,
% reverberation and disruptions for the purpose of Speech Enhancement
% If you use this script, please cite the following paper:
% TO DO
%
%
% ######################################################################


%% define important constants for the absolute paths of downloaded data sources

% paths to speech corpora

% the absolute path to downloaded emu corpus: https://mowa.clarin-pl.eu/korpusy
emuDBPath = 'C:\Users\mklec\ExperymentyMOWA\BAZY\MOWA\clarin_emu';

% the path to downloaded multilingual LibriSpeech (only PL part): https://www.openslr.org/94/
libriSpeechPLDBPath = 'C:\Users\mklec\ExperymentyMOWA\BAZY\MOWA\MultilingualLibriSpeech_mls_polish\mls_polish';

% paths to environmental scenes corpora

% the path to WHAM  http://wham.whisper.ai/
whamNoiseDBPath = 'C:\Users\mklec\ExperymentyMOWA\BAZY\MOWA\WHAM\wham_noise\wham_noise';

% the path to TUT 2027: https://zenodo.org/records/400515
tutDBPath = 'C:\Users\mklec\ExperymentyMOWA\BAZY\MOWA\TUT-acoustic-scenes-2017';

% the path to TAU-urban-acoustic-scenes
% please reorganize the data so that all of the recordings are stored in single audio
% directory!
tauDBPath = 'C:\Users\mklec\ExperymentyMOWA\BAZY\MOWA\TAU-urban-acoustic-scenes';

% paths to sound events corpora

% the path to ESC50 events https://github.com/karolpiczak/ESC-50
esc50eDBPath = 'C:\Users\mklec\ExperymentyMOWA\BAZY\MOWA\ESC-50-master\ESC-50-master\audio';

% the path to FSD50K events https://zenodo.org/records/4060432
fsd50kDBPath = 'C:\Users\mklec\ExperymentyMOWA\BAZY\MOWA\FSD50K';

%% define other important information about the corpus

% the output where the generated corpus will be stored
outputDir = 'C:\Users\mklec\ExperymentyMOWA\BAZY\MOWA\PolSMSE';

% the name of the created corpus - it will be the name of the folder which
% stores the corpus
theNameofDB = 'PolSMSE_BIG-v3';

% the desired frequency of output files. Can be 8000 or 16000Hz
outputFreq = 8000;

% how long should be the generated files in seconds. Default: 4 seconds.
% Must not be less that as the files need to have at least this length
% so that the script can choose the fragment from it of this length.
mixLength = 4;

% type one of these: test | val | train
% it denotes the subset you currently want to generate
subset = 'train';

% declare how many files you want to generate for the current subset
howManyToGenerate = 5000;

% the speech to speech ratio range when mixing two speakers
SSRrange = [-5 5];


%% here are some other constants that should not rather be changed
rng("default");
tic

% The names of generated files are 16 randomly choosen characters
s = 'abcdefghijklmnopqrstuvwxyz0123456789';
numRands = length(s);
sLength = 16;

% load the references to data sources. This file can be created using
% generateDataSources.mat
load('dataSources.mat');

% load the classes of noises and events in the form of matrix which
% specifies which event class suits to which noise class
% (the matrix has % been manually prepared)
load('backgroundClassesMatch.mat');

% load the range of parameters for reverb that suits to the particular noise class
load('reverbParamsForClasses.mat');

%% data preprocessing and the initialization

% creating absolute paths to data sources

emu_only = datasrc(datasrc.source == "emu",:);
datasrc.filePath(datasrc.source=="emu") = cellfun(@(c)fullfile(emuDBPath,c),emu_only.filePath,'uni',false);

libri_only = datasrc(datasrc.source == "libriSpeech",:);
datasrc.filePath(datasrc.source=="libriSpeech") = cellfun(@(c)fullfile(libriSpeechPLDBPath,c),libri_only.filePath,'uni',false);

wham_only = datasrc(datasrc.source == "wham",:);
datasrc.filePath(datasrc.source=="wham") = cellfun(@(c)fullfile(whamNoiseDBPath,c),wham_only.filePath,'uni',false);

tut_only = datasrc(datasrc.source == "tut",:);
datasrc.filePath(datasrc.source=="tut") = cellfun(@(c)fullfile(tutDBPath,c),tut_only.filePath,'uni',false);

tau_only = datasrc(datasrc.source == "tau",:);
datasrc.filePath(datasrc.source=="tau") = cellfun(@(c)fullfile(tauDBPath,c),tau_only.filePath,'uni',false);

esc50_only = datasrc(datasrc.source == "esc50",:);
datasrc.filePath(datasrc.source=="esc50") = cellfun(@(c)fullfile(esc50eDBPath,c),esc50_only.filePath,'uni',false);

fsd50_only = datasrc(datasrc.source == "fsd50",:);
datasrc.filePath(datasrc.source=="fsd50") = cellfun(@(c)fullfile(fsd50kDBPath,c),fsd50_only.filePath,'uni',false);



% create the main dir for the DB
if(~exist(fullfile(outputDir,theNameofDB),'dir'))
    mkdir(fullfile(outputDir,theNameofDB));
end

% create the folders for subset
if(~exist(fullfile(outputDir,theNameofDB,subset),'dir'))
    mkdir(fullfile(outputDir,theNameofDB,subset));
end

% create subfolders for storing components of the mixes

% here, there will be stored the clean speech
if(~exist(fullfile(outputDir,theNameofDB,subset,'clean'),'dir'))
    mkdir(fullfile(outputDir,theNameofDB,subset,'clean'));
end

% this folder is intended to store the final mixes
if(~exist(fullfile(outputDir,theNameofDB,subset,'mix'),'dir'))
    mkdir(fullfile(outputDir,theNameofDB,subset,'mix'));
end

% this folder is for storing sounds of audio scenes
if(~exist(fullfile(outputDir,theNameofDB,subset,'scene'),'dir'))
    mkdir(fullfile(outputDir,theNameofDB,subset,'scene'));
end

% this folder stores the sound of events
if(~exist(fullfile(outputDir,theNameofDB,subset,'event'),'dir'))
    mkdir(fullfile(outputDir,theNameofDB,subset,'event'));
end

% this folder stores the sound of reverberation
if(~exist(fullfile(outputDir,theNameofDB,subset,'reverb'),'dir'))
    mkdir(fullfile(outputDir,theNameofDB,subset,'reverb'));
end

% select the given subset from data sources
data = datasrc(datasrc.subset == subset,:);

% select the sources of speech from given subset
data_speech = data(data.role == 'speech',:);

% select the sources of scenes from given subset
data_scene = data(data.role == 'envScene',:);

% select the sources of events from given subset
data_event = data(data.role == 'events',:);

% the size of each data source type
sizeSpeech = size(data_speech,1);
sizeScene = size(data_scene,1);
sizeEvent = size(data_event,1);

% the matlab table which will be storing all the metadata about generating
% corpus
corpus = table('Size',[howManyToGenerate, 21],...
    'VariableNames',{'subset',	'speech1OryginalPath',	'speech2OryginalPath', ...
    'SSR',	'sceneOryginalPath',	'eventOryginalPath',	'speaker1File', ...
    'speaker2File',	'eventFile',	'sceneFile', ...
    'reverbForSpeaker1',	'reverbForSpeaker2',	'reverbForEvent', ...
    'mixFile',	'sceneClass',	'eventClass', 'preDelay', ...
    'highCut',	'diffusion',	'decay',	'freqDamp'}, ...
    'VariableTypes',{'string','string','string','double','string','string','string',...
    'string','string','string','string','string','string','string',...
    'string','string','double','double','double','double','double'});

%% data generation
id = 1;
while id <= howManyToGenerate

    % randomly choose speaker 1 source
    randSpeech1 = randi(sizeSpeech);
    speaker1Path = data_speech.filePath(randSpeech1);
    speaker1Duration = data_speech.duration(randSpeech1);
    speaker1SampleRate = data_speech.sampleRate(randSpeech1);
    speaker1Channels = data_speech.channels(randSpeech1);

    % randomly choose speaker 2 source
    randSpeech2 = randi(sizeSpeech);
    speaker2Path = data_speech.filePath(randSpeech2);
    speaker2Duration = data_speech.duration(randSpeech2);
    speaker2SampleRate = data_speech.sampleRate(randSpeech2);
    speaker2Channels = data_speech.channels(randSpeech2);

    % it they are the same, continue selection with others...
    if(randSpeech2 == randSpeech1)
        continue;
    end

    % randomly choose the sources of scene
    randScene = randi(sizeScene);
    scenePath = data_scene.filePath(randScene);
    sceneDuration = data_scene.duration(randScene);
    sceneSampleRate = data_scene.sampleRate(randScene);
    sceneChannels = data_scene.channels(randScene);
    sceneClass = data_scene.class(randScene);

    % next, the event should suit to the scene class. Here, the matrix with
    % scene and event classes is utilized...

    % chosing non empty indexes from the matrix of the scene class column
    idcl = ~cellfun(@isempty,string(backgroundClasses.(string(sceneClass))));

    % filter the eventClass that suits to the scene class and randomly
    % choose one of the class
    suitEC = rmmissing(backgroundClasses.eventClass(idcl));
    choosenEventClass = suitEC(randi(size(suitEC,1)));

    % now randomly chosing the event which contains given class (it should
    % already suit to the scene class)
    foundECIdxs = cell2mat(cellfun(@(c)contains(c,choosenEventClass),string(data_event.class),'uni',false));
    suitableEvents = data_event(foundECIdxs,:);

    % just in case...
    if(isempty(suitableEvents))
        continue
    end

    % randomly choosing the event from those that suits to the scene class
    randEvent = randi(size(suitableEvents,1));
    eventPath = suitableEvents.filePath(randEvent);
    eventDuration = suitableEvents.duration(randEvent);
    eventSampleRate = suitableEvents.sampleRate(randEvent);
    eventChannels = suitableEvents.channels(randEvent);

    % now randomly select the given audio fragment (mixLenght) from each of each the
    % component' file (assuming the the component's file are longer than
    % mixLength)

    speech1samples = speaker1Duration * speaker1SampleRate;
    speaker1segmentL = speaker1SampleRate * mixLength;
    speaker1segmentStart = randi(ceil(speech1samples - speaker1segmentL));
    speaker1segmentEnd = speaker1segmentStart +speaker1segmentL-1;
    [ySpeech1, fsSpeech1] = audioread(speaker1Path,[speaker1segmentStart,speaker1segmentEnd]);
    ySpeech1 = removeClipping(ySpeech1);

    speech2samples = speaker2Duration * speaker2SampleRate;
    speaker2segmentL = speaker2SampleRate * mixLength;
    speaker2segmentStart = randi(ceil(speech2samples - speaker2segmentL));
    speaker2segmentEnd = speaker2segmentStart +speaker2segmentL-1;
    [ySpeech2, fsSpeech2] = audioread(speaker2Path,[speaker2segmentStart,speaker2segmentEnd]);
    ySpeech2 = removeClipping(ySpeech2);

    sceneSamples = sceneDuration * sceneSampleRate;
    sceneSegmentL = sceneSampleRate * mixLength;
    sceneSegmentStart = randi(ceil(sceneSamples - sceneSegmentL));
    sceneSegmentEnd = sceneSegmentStart + sceneSegmentL-1;
    [yScene, fsScene] = audioread(scenePath,[sceneSegmentStart,sceneSegmentEnd]);
    yScene = removeClipping(yScene);

    eventSamples = eventDuration * eventSampleRate;
    eventSegmentL = eventSampleRate * mixLength;
    eventSegmentStart = randi(ceil(eventSamples - eventSegmentL));
    eventSegmentEnd = eventSegmentStart + eventSegmentL-1;
    [yEvent, fsEvent] = audioread(eventPath,[eventSegmentStart,eventSegmentEnd]);
    yEvent = removeClipping(yEvent);

    % convert to mono if the components are in stereo

    if(speaker1Channels == 2)
        ySpeech1 = (ySpeech1(:,1)+ySpeech1(:,2))/2;
    end

    if(speaker2Channels == 2)
        ySpeech2 = (ySpeech2(:,1)+ySpeech2(:,2))/2;
    end

    if(sceneChannels == 2)
        yScene = (yScene(:,1)+yScene(:,2))/2;
    end

    if(eventChannels == 2)
        yEvent = (yEvent(:,1)+yEvent(:,2))/2;
    end


    % resample to desired outputFrequency

    if(fsSpeech1 ~= outputFreq)
        ySpeech1 = audioresample(ySpeech1,InputRate=fsSpeech1,OutputRate=outputFreq);
        fsSpeech1 = outputFreq;
    end

    if(fsSpeech2 ~= outputFreq)
        ySpeech2 = audioresample(ySpeech2,InputRate=fsSpeech2,OutputRate=outputFreq);
        fsSpeech2 = outputFreq;
    end

    if(fsScene ~= outputFreq)
        yScene = audioresample(yScene,InputRate=fsScene,OutputRate=outputFreq);
        fsScene = outputFreq;
    end

    if(fsEvent ~= outputFreq)
        yEvent = audioresample(yEvent,InputRate=fsEvent,OutputRate=outputFreq);
        fsEvent = outputFreq;
    end


    % randomly select the speech to speech ratio and mix the speech
    speechRatio = randi(SSRrange);
    [speechMix,ySpeech1,ySpeech2] = mixSignals(ySpeech1,ySpeech2,speechRatio);
    ySpeech2 = removeClipping(ySpeech2);
    speechMix = removeClipping(speechMix);

    % next, check if the scene class is indoor or not. If indoor than apply
    % reverberation to the speech and events. In such a case the speech and
    % events will have the same reverberation parameters, except the first replection time.

    % check if scene is indoor or not
    where = backgroundClasses.(string(sceneClass))(2);

    % than apply reverberation for only indoor classes
    if(where == "in")

        % read the reverb settings depending on the class
        rset = reverbSettings(reverbSettings.sceneClass == string(sceneClass),:);

        % just in case...
        if(isempty(rset))
            continue
        end

        % randomly choosing the reverb parameters from the range encoded in
        % reverbParamsForClasses.mat for given scene class

        % Pre-delay is the time between hearing direct sound and
        % the first early reflection.
        % The value of PreDelay is proportional to the size of the room being modeled.
        tpd = split(string(rset.preDelay)," ");
        tpd2 = [str2double(tpd(1)) str2double(tpd(2))];
        preDelay = tpd2(1) + rand*(tpd2(2)-tpd2(1));

        % Lowpass filter cutoff is the –3 dB cutoff frequency.
        % It prevents reverberation to high-frequency of the input.
        thc = split(string(rset.highCut)," ");
        thc2 = [str2double(thc(1)) str2double(thc(2))];
        highCut = thc2(1) + rand*(thc2(2)-thc2(1));

        % Diffusion is proportional to the rate at which the
        % reverb tail builds in density.
        % Increasing Diffusion pushes the reflections closer together,
        % thickening the sound. Reducing Diffusion creates more discrete echoes.
        tdif = split(string(rset.diffusion)," ");
        tdif2 = [str2double(tdif(1)) str2double(tdif(2))];
        diffusion = tdif2(1) + rand*(tdif2(2)-tdif2(1));

        %is inversely proportional to the time it takes for reflections
        % to run out of energy.
        % To model a large room, use a long reverb tail (low decay factor).
        % To model a small room, use a short reverb tail (high decay factor).;
        tde = split(string(rset.decay)," ");
        tde2 = [str2double(tde(1)) str2double(tde(2))];
        decay = tde2(1) + rand*(tde2(2)-tde2(1));

        % HighFrequencyDamping is proportional to the attenuation of high
        % frequencies in the reverberation output.
        % Setting HighFrequencyDamping to a large value makes high-frequency
        % reflections decay faster than low-frequency reflections.
        tfe = split(string(rset.freqDamp)," ");
        tfe2 = [str2double(tfe(1)) str2double(tfe(2))];
        freqDamp =  tfe2(1) + rand*(tfe2(2)-tfe2(1));

        % generate fully wet reverb for speech

        [reverbForSpeaker1] = generateReverb(ySpeech1,outputFreq,preDelay,highCut,diffusion,decay,freqDamp,1);
        [reverbForSpeaker2] = generateReverb(ySpeech2,outputFreq,preDelay,highCut,diffusion,decay,freqDamp,1);

        % generate reverb for event
        % use the same reverb as for speech but with different preDelay
        preDelayForEvent = tpd2(1) + rand*(tpd2(2)-tpd2(1));
        [reverbForEvent] = generateReverb(yEvent,outputFreq,preDelayForEvent,highCut,diffusion,decay,freqDamp,1);

        % do the mix of scene with sound event with all the reverberations
        % (also for speakers)
        mixBackground = yScene + yEvent + reverbForEvent + reverbForSpeaker1 + reverbForSpeaker2;
        mixBackground = removeClipping(mixBackground);

        % do the mix of background and speech + reverb for speech
        mixAll = mixBackground + speechMix;
        mixAll = removeClipping(mixAll);

    else % when the scene class in outdoor then there is no reverb

        % do the mix of scene with sound event
        mixBackground = yEvent + yScene;
        mixBackground = removeClipping(mixBackground);

        % do the mix of background and speech
        mixAll = mixBackground + speechMix;
        mixAll = removeClipping(mixAll);

    end

    % generating names for storing files

    speaker1File = s(ceil(rand(1,sLength)*numRands));
    speaker2File = s(ceil(rand(1,sLength)*numRands));

    eventFile = s(ceil(rand(1,sLength)*numRands));
    sceneFile = s(ceil(rand(1,sLength)*numRands));
    reverbFile = s(ceil(rand(1,sLength)*numRands));

    if(where == "in")
        noiseAllFile = [sceneFile '-' eventFile '-' reverbFile];
    else
        noiseAllFile = [sceneFile '-' eventFile];
    end

    mixFile = [speaker1File '-' speaker2File '-' noiseAllFile];

    % adding extentions to file names
    speaker1FileName = [speaker1File '.wav'];
    speaker2FileName = [speaker2File '.wav'];
    sceneFileName = [sceneFile '.wav'];
    eventFileName = [eventFile '.wav'];
    reverbForSpeaker1File = ['sp1_' reverbFile '.wav'];
    reverbForSpeaker2File = ['sp2_' reverbFile '.wav'];
    reverbForEventFile = ['ev_' reverbFile '.wav'];
    mixFileName = [mixFile '.wav'];

    % adding information to metadata file
    corpus.subset(id) = string(subset);
    corpus.speech1OryginalPath(id) = speaker1Path;
    corpus.speech2OryginalPath(id) = speaker2Path;
    corpus.sceneOryginalPath(id) = string(scenePath);
    corpus.eventOryginalPath(id) = string(eventPath);

    corpus.speaker1File(id) = string(speaker1FileName);
    corpus.speaker2File(id) = string(speaker2FileName);
    corpus.SSR(id) = speechRatio;
    corpus.eventFile(id) = string(eventFileName);
    corpus.sceneFile(id) = string(sceneFileName);
    corpus.mixFile(id) = string(mixFileName);
    if(where == "in")
        corpus.reverbForSpeaker1(id) = string(reverbForSpeaker1File);
        corpus.reverbForSpeaker2(id) = string(reverbForSpeaker2File);
        corpus.reverbForEvent(id) = string(reverbForEventFile);
    end

    corpus.sceneClass(id) = string(sceneClass);
    corpus.eventClass(id) = string(choosenEventClass);

    if(where == "in")
        corpus.preDelay(id) = preDelay;
        corpus.highCut(id) = highCut;
        corpus.diffusion(id) = diffusion;
        corpus.decay(id) = decay;
        corpus.freqDamp(id) = freqDamp;
    else
        corpus.preDelay(id) = NaN;
        corpus.highCut(id) = NaN;
        corpus.diffusion(id) = NaN;
        corpus.decay(id) = NaN;
        corpus.freqDamp(id) = NaN;
    end

    % save speaker 1
    audiowrite(fullfile(outputDir,theNameofDB,subset,'clean',speaker1FileName),ySpeech1,outputFreq);

    % save speaker 2
    audiowrite(fullfile(outputDir,theNameofDB,subset,'clean',speaker2FileName),ySpeech2,outputFreq);

    % save mix
    audiowrite(fullfile(outputDir,theNameofDB,subset,'mix',mixFileName),mixAll,outputFreq);

    % save scene
    audiowrite(fullfile(outputDir,theNameofDB,subset,'scene',sceneFileName),yScene,outputFreq);

    % save event
    audiowrite(fullfile(outputDir,theNameofDB,subset,'event',eventFileName),yEvent,outputFreq);

    % save reverb
    if(where == "in")
        audiowrite(fullfile(outputDir,theNameofDB,subset,'reverb',reverbForSpeaker1File),reverbForSpeaker1,outputFreq);
        audiowrite(fullfile(outputDir,theNameofDB,subset,'reverb',reverbForSpeaker2File),reverbForSpeaker2,outputFreq);
        audiowrite(fullfile(outputDir,theNameofDB,subset,'reverb',reverbForEventFile),reverbForEvent,outputFreq);
    end

    % temporary save the metadata file at every 10000 files, as a backup
    if(mod(id,10000)==0)
        save(['corpus_' theNameofDB '_' num2str(id) '_' subset '_backup.mat'],'corpus');
    end


    disp(num2str(id));
    id = id + 1;
end

%% save the final created metadata file to disc
save(['corpus_' theNameofDB '_' subset '_final.mat'],'corpus');

toc
