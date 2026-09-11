% 清空所有
clear all;
close all;

% 載入YAMNet模型
YAMNetLocation = 'D:\voice\horn_yamnet';
addpath(fullfile(YAMNetLocation,'yamnet'));
[net, classNames] = audioPretrainedNetwork("yamnet");

% 音訊設定
fs = 44100; % 原始採樣率
nBits = 16;
nChannels = 1;
ID = -1; % -1 為預設音訊輸入裝置
recObj = audiorecorder(fs, nBits, nChannels, ID);
recordDuration = 1.5; % 設定錄音時長

% 初始化歷史紀錄
hornDetected = [];
speechDetected = [];
timeStamps = [];
amplitudeData = [];
audioHistory = [];

% 繪圖窗口設置
figure;
subplot(3,1,3);
hold on;
xlabel('Time (s)');
ylabel('Horn Detected');
title('Horn Detection Over Time');
ylim([-0.1, 1.1]); % 限制 y 軸範圍
yticks([0, 1]);
yticklabels({'False', 'True'});
grid on;

subplot(3,1,2);
hold on;
xlabel('Time (s)');
ylabel('Speech Detected');
title('Speech Detection Over Time');
ylim([-0.1, 1.1]); % 限制 y 軸範圍
yticks([0, 1]);
yticklabels({'False', 'True'});
grid on;

subplot(3,1,1);
hold on;
xlabel('Time (s)');
ylabel('Amplitude');
title('Audio Amplitude Over Time');
grid on;

while true
    % 錄音
    disp('開始錄音...');
    recordblocking(recObj, recordDuration);
    disp('錄音結束');

    % 獲取錄音數據
    audioData = getaudiodata(recObj);
    audioHistory = [audioHistory; audioData]; % 累積歷史音訊數據

    % 移除前0.5秒的數據
    samplesToRemove = round(0.5 * fs);
    audioData = audioData(samplesToRemove+1:end);
    audioData = audioData / max(abs(audioData));

    % 計算振幅
    maxAmplitude = max(abs(audioData));

    % 使用YAMNet進行預測
    spectrograms = yamnetPreprocess(audioData, fs);
    scores = predict(net, spectrograms);

    % 計算每個類別的平均分數
    meanScores = mean(scores, 1);

    % 找出第一名的預測分數及其對應的類別
    [~, maxIndex] = max(meanScores);
    topClass = classNames{maxIndex};
    topScore = meanScores(maxIndex);

    % 檢查是否偵測到 "horn" 類別
    hornClasses = {'Vehicle horn, car horn, honking', 'Air horn, truck horn', 'Train horn'};
    hornDetectedThisTime = ismember(topClass, hornClasses);

    % 檢查是否偵測到 "Speech" 類別
    speechClasses = {'Speech', 'Conversation'};
    speechDetectedThisTime = ismember(topClass, speechClasses);

    % 更新歷史紀錄
    hornDetected = [hornDetected, hornDetectedThisTime];
    speechDetected = [speechDetected, speechDetectedThisTime];
    timeStamps = [timeStamps, length(timeStamps) * recordDuration]; % 假設每次錄音間隔 recordDuration 秒
    amplitudeData = [amplitudeData, maxAmplitude]; % 記錄最大振幅

    % 繪製圖表
    subplot(3,1,3);
    plot(timeStamps, hornDetected, '-o');
    subplot(3,1,2);
    plot(timeStamps, speechDetected, '-x');
    subplot(3,1,1);
    t = (0:length(audioHistory)-1) / fs; % 計算時間軸
    plot(t, audioHistory);
    drawnow;
end
