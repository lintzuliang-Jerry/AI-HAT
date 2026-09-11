clear all;
close all;

% 導入Java類
import java.awt.Robot;
import java.awt.event.KeyEvent;

% 創建Robot對象
rob = Robot();

% 設置參數
fs = 44100; % 採樣率
frameLength = 0.05; % 幀長度（秒）
frameSize = round(fs * frameLength); % 每幀的採樣點數
historyDuration = 10; % 歷史記錄持續時間（秒）
bufferSize = round(fs * historyDuration); % 緩衝區大小（10秒的數據）
flag1 = 0;
flag2 = 0;
flag3 = 0;
isKeyPressed = false; % 新增變量來追踪按鍵狀態

% 初始化音頻設備讀取器
audioReader = audioDeviceReader('SampleRate', fs, 'SamplesPerFrame', frameSize);

% 初始化緩衝區
buffer = zeros(bufferSize, 1);
detectionBuffer = zeros(bufferSize, 1);

disp('開始錄音和處理');

% 持續錄音和處理
while true
    % 讀取一幀音頻
    audioIn = audioReader();

    % 更新緩衝區
    buffer = [buffer(frameSize+1:end); audioIn];

    % 進行語音檢測
    idx = detectSpeech(buffer, fs, 'Window', hamming(frameSize, 'periodic'), 'MergeDistance', round(0.3*fs));

    if ~isempty(idx)
        if idx(1,1) == 1
            idx(1,2) = 1;
        end

        if flag1 ~= size(idx, 1)
            if ~isKeyPressed
                disp('語音信號開始');
                % 按下F2鍵
                rob.keyPress(KeyEvent.VK_F2);
                isKeyPressed = true;
            end
            flag1 = size(idx, 1);
            flag3 = 1;
        elseif flag2 == idx(end,2) - idx(end,1)
            if flag3 == 1
                disp('語音信號結束');
                % 釋放F2鍵
                if isKeyPressed
                    rob.keyRelease(KeyEvent.VK_F2);
                    isKeyPressed = false;
                end
                flag3 = 0;
            end
        end

        flag2 = idx(end,2) - idx(end,1);

        % 更新檢測結果緩衝區
        detectionBuffer = [detectionBuffer(frameSize+1:end); zeros(frameSize, 1)];
        for i = 1:size(idx, 1)
            detectionBuffer(idx(i,1):idx(i,2)) = 1;
        end
    end
end
