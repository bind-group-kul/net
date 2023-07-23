function [ ] = net_spm2edf( varargin )
%NET_SPM2EDF Convert a SPM MEEG data object to EDF format, at the same
%location and with the same name of the original file
%   INPUT:
%           spm_file: the SPM MEEG *.mat file, which is the full path of 
%           the MEEG object to be converted
%
%           [optional] target EDF file full path: If not defined, then the
%           function convert the MEEG file to EDF file at the same place
%           with the same name as MEEG file.
%
%   Important notes:
%       1. EDF uses 16bit integer and corresponding max/min to save data. 
%       This compression reduces the quatification resolution of original 
%       data, if the original data is sampled with quatification level more 
%       than 16 bit. When read 16bit EDF back, it will convert 16bit integer
%       to fload, but what's lost is already lost. This effects little on 
%       EEG data
%
%       2. EDF requires data length to be exact number of seconds, this can
%       cause artifact at the conjuction point in the end of the data where
%       zeros are appended
%
%   by Mingqi Zhao @ BIND Group
%


%% prepare data, edf requires data len to be exact number of seconds. This can cause artifact at the conjuction point when filtering on EDF file
    if(nargin == 0)
        error('Input required!');
    elseif(nargin == 1)
        spm_file = varargin{1};
        output_file = [spm_file(1:end-3), 'edf'];
    elseif(nargin == 2)
        spm_file = varargin{1};
        output_file = varargin{2};
    end
    
    D = spm_eeg_load(spm_file);
    fs = D.fsample;
    nsamp = D.nsamples;
    nch = D.nchannels;

    data = [D(:,:), zeros(nch, fs - mod(nsamp, fs))];
    
    
    events = D.events;
    
    
%% prepare head info
     dt = datetime;
     
     header.numtimeframes = nsamp;
     header.samplingrate = fs;
     header.numchannels = nch;
     header.numauxchannels = 0; 
     header.year = year(dt);
     header.month = month(dt);
     header.day = day(dt);
     header.hour = hour(dt);
     header.minute = minute(dt);
     header.second = round(second (dt));
     header.ID = 'Undefined';
     header.technician = 'NET_toolbox';
     header.equipment = 'NET';
     header.subject.ID = 'Undefined';
     header.subject.sex = 'M';
     header.subject.name = 'ANONYMOUS';
     header.subject.year = 1999';
     header.subject.month = 1;
     header.subject.day = 1;
     
     if(length(events) == 1 && isempty(events(1).time))
         disp('No events found!');
     else
         for iter_e = 1:length(events)
             header.events.POS(1, iter_e) = events(iter_e).time;
             if(~isempty(events(iter_e).duration))
                header.events.DUR(1, iter_e) = events(iter_e).duration;
             else
                header.events.DUR(1, iter_e) = 1;
             end
             header.events.TYP{1, iter_e} = events(iter_e).value;
         end
     end
     
     % channel specific info
     for iter_ch = 1:nch
         header.channels{iter_ch, 1} = [D.chantype{iter_ch}, ' ', D.chanlabels{iter_ch}];
         header.physical_dim{iter_ch, 1} = D.units{iter_ch};
     end

%% call the function from
     lab_write_edf(output_file, data, header);
     
end

function lab_write_edf(filename,data,header)
% Original Code:
% Stefan Klanke 2010
%
% Modifications:
% 2011-02-03: 10:48:53Z roboos $
% 2012-04-26: F. Hatz Neurology Basel (added support for EDF+)
%
% data = matrix (channels x timeframes)
% header - structured information about the read eeg data
%      header.numtimeframes - length of EEG data
%      header.samplingrate = samplingrate
%      header.numchannels - number of channels
%      header.numauxchannels - number of non EEG channels (only ECG channel is recognized)
%      header.channels - channel labels
%      header.year = year ('yyyy') of recording
%      header.month = month ('mm') of recording
%      header.day = day ('dd') of recording
%      header.hour = hour ('hh') of recording
%      header.minute = minute ('mm') of recording
%      header.second - second ('ss') of recording
%      header.ID - EEG number
%      header.technician - responsible investigator or technician ('space' not allowed, replaced with '_')
%      header.equipment - used equipment ('space' not allowed, replaced with '_')
%      header.subject.ID - local patient identification ('space' not allowed, replaced with '_')
%      header.subject.sex - 'M' or 'F'
%      header.subject.name - patients name ('space' not allowed, replaced with '_')
%      header.subject.year - birthdate ('yyyy') 
%      header.subject.month - birthdate ('mm')
%      header.subject.day - birthdate ('dd')
%      header.events.POS = vector with positions in TF
%      header.events.DUR = vector with duration in TF
%      header.events.TYP = vector with cells containing names of events
tmp = strfind(filename,'.');
if ~isempty(tmp)
    filename = [filename(1:tmp(end)) 'edf'];
else
    filename = [filename '.edf'];
end
clearvars tmp

[nChans,N] = size(data);
if size(header.channels) ~= nChans
  error 'Data dimension does not match header information';
end 

% Control for errors
if nChans > 9999
  error 'Cannot write more than 9999 channels to an EDF file.';
end
if N > 99999999
  error 'Cannot write more than 99999999 data records (=samples) to an EDF file.';
end

if ~isreal(data)
    error 'Cannot write complex-valued data.';
end

% Create Labels
if ~iscell(header.channels)
    header.channels =  cellstr(header.channels);
end
if isfield(header,'events')
    header.channels(end+1,1) = cellstr('EDF Annotations');
    header.physical_dim{end+1} = ' ';
    
    nChans = nChans + 1;
end

labels = char(32*ones(nChans, 16));
for n=1:nChans
  ln = length(header.channels{n});
  if ln > 16
    fprintf(1, '     Warning: truncating label %s to %s\n', header.channels{n}, header.channels{n}(1:16));
    ln = 16;
  end
  labels(n,1:ln) = header.channels{n}(1:ln);
end

% Scale and convert to in16 (data)
maxV = max(data, [], 2);
minV = min(data, [], 2);
if max(maxV) > 3277 || min(minV) < -3277
    disp('     Some data > 16-bit integer, extreme values floored');
    data(data > 3277) = 3277; 
    data(data < -3277) = -3277;
    maxV = max(data, [], 2);
    minV = min(data, [], 2);
end
maxV = max(data, [], 2);
minV = min(data, [], 2);
maxdata = max([max(maxV) abs(min(minV))]);
Scale = 32767 / maxdata;
maxV = int16(repmat(maxdata,size(data,1),1));
minV = int16(repmat(-maxdata,size(data,1),1));
maxVc = repmat(32767,size(data,1),1);
minVc = repmat(-32767,size(data,1),1);
data = (data .* Scale);
clearvars Scale

if ~strcmp(class(data),'int16')
  data = int16(data);
end

% Add zeros at end of data (data-length must be multiple of a second)
data = cat(2,data,zeros(size(data,1),(ceil(N/header.samplingrate)*header.samplingrate)-size(data,2)));

% Create events channel
if isfield(header,'events')
    minV(end+1,1) = -32768;
    maxV(end+1,1) = 32767;
    minVc(end+1,1) = -32768;
    maxVc(end+1,1) = 32767;
    recordstmp = zeros(1,ceil(N/header.samplingrate));
    eventchannel =repmat(uint8(00),240,ceil(N/header.samplingrate));
    for i = 1:ceil(N/header.samplingrate)
        tmp = unicode2native(num2str(i-1));
        tmp = [43 tmp 20 20 00];
        eventchannel(1:length(tmp),i) = tmp';
        recordstmp(1,i) = length(tmp);
    end
    clearvars tmp
    for i = 1:size(header.events.POS,2)
        %tmpPOS = unicode2native(num2str(round(1000* double(header.events.POS(1,i)) / header.samplingrate) / 1000));
        %tmpDUR = unicode2native(num2str(round(1000* double(header.events.DUR(1,i)) / header.samplingrate) / 1000));
        tmpPOS = unicode2native(num2str(header.events.POS(1,i)));
        tmpDUR = unicode2native(num2str(header.events.DUR(1,i)));
        if(isempty(header.events.TYP{1,i}))
            header.events.TYP{1,i} = 'NoName';
        end
        tmpTYP = unicode2native(header.events.TYP{1,i});
        eventchanneltmp = [43 tmpPOS 21 tmpDUR 20 tmpTYP 20 00];
        %j = ceil(double(header.events.POS(1,i)) / header.samplingrate);
        j = 1; % always no offset
        eventchannel(recordstmp(1,j)+1:recordstmp(1,j) + length(eventchanneltmp),j) = eventchanneltmp';
        recordstmp(1,j) =  recordstmp(1,j) + length(eventchanneltmp);
    end
    clearvars tmpPOS tmpDUR tmpTYP eventchanneltmp
    if ceil(size(eventchannel,1) / 2) > (size(eventchannel,1) / 2)
        eventchannel = cat(1,eventchannel,repmat(uint8(00),1,ceil(N/header.samplingrate)));
    end
    lengthevents = size(eventchannel,1) / 2;
    eventchannel = reshape(eventchannel,1,size(eventchannel,1)*size(eventchannel,2));
    eventchannel = typecast(eventchannel','int16')';
    eventchannel = reshape(eventchannel,lengthevents,length(eventchannel)/lengthevents);
    data = reshape(data,size(data,1),header.samplingrate,ceil(N/header.samplingrate));
    data = permute(data,[2 1 3]);
    data = reshape(data,size(data,1) * size(data,2),size(data,3));
    data = cat(1,data,eventchannel);
else
    data = reshape(data,size(data,1),header.samplingrate,ceil(N/header.samplingrate));
    data = permute(data,[2 1 3]);
    data = reshape(data,size(data,1) * size(data,2),size(data,3));
end

%Convert digMin digMax physMin physMax to char-array
digMin = sprintf('%-8i', minVc);
digMax = sprintf('%-8i', maxVc);
physMin = sprintf('%-8i', minV);
physMax = sprintf('%-8i', maxV);

% Control EEG recording timestamp
if ~isfield(header,'month')
    header.year = 1970;
    header.month = 1;
    header.day = 1;
end
if ~isfield(header,'hour')
    header.hour = 0;
    header.minute = 0;
end
if header.month == 0
    header.year = 1970;
    header.month = 1;
    header.day = 1;
end
tmp = {'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul'; ...
    'Aug';'Sep';'Oct';'Nov';'Dec'};
if header.month >= 1 && header.month <= 12
    monthstr = upper(tmp{round(header.month)});
else
    monthstr = upper('Jan');
end
clearvars tmp
if header.year > 2000
    yearshort = header.year - 2000;
elseif header.year > 1900
    yearshort = header.year - 1900;
elseif header.year > 100
    yearshort = header.year - (100*floor(header.year/100));
else
    yearshort = header.year;
end

% Control Recording and Subject info
if ~isfield(header,'ID')
    header.ID = 'X';
end
if ~isfield(header,'technician') || isempty(header.technician)
    header.technician = 'X';
end
if ~isfield(header,'equipment') || isempty(header.equipment)
    header.equipment = 'X';
end
if ~isfield(header,'subject')
    header.subject = [];
end
if ~isfield(header.subject,'ID') || isempty(header.subject.ID)
    tmp = strfind(filename,filesep);
    if ~isempty(tmp)
        header.subject.ID = filename(tmp(end)+1:end-4);
    else
        header.subject.ID = filename(1:end-4);
    end
    clearvars tmp
end
if ~isfield(header.subject,'sex') || isempty(header.subject.sex)
    header.subject.sex = 'X';
end
if ~isfield(header.subject,'name') || isempty(header.subject.name)
    header.subject.name = 'X';
end
if ~isfield(header.subject,'year')
    header.subject.birthdate = 'X';
else
    tmp = {'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul'; ...
        'Aug';'Sep';'Oct';'Nov';'Dec'};
    if header.subject.month >= 1 && header.subject.month <= 12
        tmp2 = upper(tmp{round(header.subject.month)});
    else
        tmp2 = upper('Jan');
    end
    header.subject.birthdate = [num2str(header.subject.day,'%02i') '-' tmp2 '-' num2str(header.subject.year,'%04i')];
    clearvars tmp tmp2
end
header.subject.ID = regexprep(header.subject.ID,' ','_');
header.subject.name = regexprep(header.subject.name,' ','_');
header.technician = regexprep(header.technician,' ','_');
header.equipment = regexprep(header.equipment,' ','_');
if length(header.subject.sex) > 1
    header.subject.sex = 'X';
end

% Create physdim-info (uV for all channels)
physdim = [];
for iter_ch = 1:nChans
    tmp_dim = header.physical_dim{iter_ch};
    tmp_dim = [tmp_dim, repmat(' ', 1, 8-length(tmp_dim))];
    physdim = [physdim; tmp_dim];
end

% Write edf
fid = fopen(filename, 'wb', 'ieee-le');

% write 8 ascii version
    fprintf(fid, '0       ');
% write 80 ascii patient id
    fprintf(fid, '%-80s', [header.subject.ID ' ' header.subject.sex ' ' header.subject.birthdate ' ' header.subject.name]);
% write 80 ascii recording id
    fprintf(fid,'%-80s', ['Startdate ' num2str(header.day,'%02i') '-' monthstr '-' num2str(header.year,'%04i') ' ' header.ID ' ' header.technician ' ' header.equipment]);
% write 8 ascii start date
    fprintf(fid, '%02i.%02i.%02i', header.day, header.month, yearshort); % date as dd.mm.yy
% write 8 ascii start time
    fprintf(fid, '%02i.%02i.%02i', header.hour, header.minute, 0); % time as hh.mm.ss
% write 8 ascii number of bytes
    fprintf(fid, '%-8i', 256*(1+nChans));  % number of bytes in header
% write 44 ascii reserved
    if isfield(header,'events')
        fprintf(fid, '%-44s', 'EDF+C'); % reserved (44 spaces) continous EDF+ file with annotations
    else
        fprintf(fid, '%44s', ' '); % reserved (44 spaces) EDF file without annotations
    end
% 8 ascii number of data records
    fprintf(fid, '%-8i', ceil(N/header.samplingrate));  % number of EEG records
% 8 ascii duration of data records
    fprintf(fid, '%8f', 1);  % duration of EEG record (=Fs)
% 4 ascii number of signals ns in data records
    fprintf(fid, '%-4i', nChans);  % number of signals = channels
% ns*16 ascii type label
    fwrite(fid, labels', 'char*1'); % labels
% ns*80 ascii transducer type
    fwrite(fid, 32*ones(80,nChans), 'uint8'); % transducer type (all spaces)
fwrite(fid, physdim', 'char*1'); % phys dimension (all spaces)
fwrite(fid, physMin', 'char*1'); % physical minimum
fwrite(fid, physMax', 'char*1'); % physical maximum
fwrite(fid, digMin', 'char*1'); % digital minimum
fwrite(fid, digMax', 'char*1'); % digital maximum
fwrite(fid, 32*ones(80,nChans), 'uint8'); % prefiltering (all spaces)
if isfield(header,'events')
    for k=1:(nChans-1)
        fprintf(fid, '%-8i', header.samplingrate); % samples per record (= samplingrate)
    end
    fprintf(fid, '%-8i', lengthevents); % samples for annotations per record
else
    for k=1:nChans
        fprintf(fid, '%-8i', header.samplingrate); % samples per record (= samplingrate)
    end
end
fwrite(fid, 32*ones(32,nChans), 'uint8'); % reserverd (32 spaces / channel)
fwrite(fid, data, 'int16');
fclose(fid);
end
