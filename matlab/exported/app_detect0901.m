classdef app_detect0901 < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        Label1                      matlab.ui.control.Label
        SpeechRecognitionEditField  matlab.ui.control.EditField
        SpeechRecognitionEditFieldLabel  matlab.ui.control.Label
        WordLabel                   matlab.ui.control.Label
        STOPButton                  matlab.ui.control.Button
        STARTButton                 matlab.ui.control.Button
        UIAxes2                     matlab.ui.control.UIAxes
        UIAxes                      matlab.ui.control.UIAxes
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: STOPButton
        function STOPButtonPushed(app, event)
            delete(app);
        end

        % Button pushed function: STARTButton
        function STARTButtonPushed(app, event)
            global s;  % 定義全域變數s，用於管理串列埠連接

            %% 初始化
            app.WordLabel.Text = '';  % 初始化GUI應用程式中的文字標籤為空

            import java.awt.*;  % 匯入Java AWT（Abstract Window Toolkit）類別庫，允許使用Java GUI功能
            import java.awt.event.*;  % 匯入Java AWT事件類別庫，用於處理鍵盤事件

            % 建立一個Robot對象來模擬鍵盤按鍵
            rob = Robot;  % 創建Java的Robot對象，用來模擬鍵盤和滑鼠操作

            % 音訊設定
            fs = 44100;  % 設定音訊採樣率為44100 Hz，這是CD音質標準
            nBits = 16;  % 設定錄音位元數為16位，這是常見的音訊位元深度
            nChannels = 1;  % 設定單聲道錄音
            ID = -1;  % 設定音訊輸入裝置為預設（-1表示預設裝置）
            recObj = audiorecorder(fs, nBits, nChannels, ID);  % 創建音訊錄製物件
            recordDuration = 1.1;  % 設定錄音時長為1.1秒

            % 無限循環的變數初始化
            frame_size = 512;  % 設定音訊框大小為512樣本，用於短時傅立葉變換（STFT） (一幀長度)
            speech_flag = 0;  % 初始化語音標記，標記是否偵測到語音
            F2_flag = 0;  % 初始化F2鍵標記，標記是否按下了F2鍵

            %% 主迴圈
            while true
                % 聚焦到語音識別輸入框並清空
                focus(app.SpeechRecognitionEditField);  % 將焦點設置到應用程式中的語音識別輸入框

                % 如果F2_flag為0，模擬按下F2鍵
                if F2_flag == 0
                    rob.keyPress(KeyEvent.VK_F2);  % 使用Robot對象模擬按下F2鍵
                end

                % 檢查並建立串列埠連接
                if isempty(s)
                    s = serialport("COM5", 9600);  % 初始化串列埠"COM5"並設定波特率為9600
                    fopen(s);  % 開啟串列埠連接
                end

                % 開始錄音
                record(recObj);  % 開始錄音
                pause(recordDuration);  % 等待錄音結束

                % 獲取錄製的音訊資料並進行正規化處理
                speech = getaudiodata(recObj);  % 獲取錄製的音訊資料
                speech = speech / max(abs(speech));  % 將音訊訊號正規化至-1到1的範圍

                %% 語音判斷
                len_speech = length(speech);  % 獲取音訊訊號長度
                frame_no = len_speech / frame_size;  % 計算總幀數

                egy_mat = zeros(1, frame_no);  % 初始化能量矩陣
                for cnt3 = 1:frame_no
                    init1 = (cnt3 - 1) * frame_size + 1;  % 計算當前幀的起始索引
                    end1 = cnt3 * frame_size;  % 計算當前幀的結束索引
                    frame1 = speech(init1:end1);  % 提取當前幀的音訊資料
                    egy = 10 * log10(frame1' * frame1);  % 計算當前幀的能量（對數刻度）
                    egy_mat(cnt3) = egy;  % 將能量值儲存在矩陣中
                end

                result = 0 * speech;  % 初始化結果向量
                speech_frame = sum(egy_mat > -5);  % 計算超過能量閾值的語音幀數
                background_frame = sum(egy_mat <= 0);  % 計算低於能量閾值的背景噪音幀數

                % 檢查語音和背景幀數以決定是否進行語音處理
                if speech_frame >= 5
                    speech_flag = 1;  % 語音標記設置為1，表示檢測到語音
                end

                app.Label1.Text = '';  % 清空應用程式中的標籤文字
                if speech_flag == 1 && background_frame >= 5  % 如果語音標記和背景噪音條件都滿足
                    speech_flag = 0;  % 重置語音標記
                    idx = detectSpeech(speech, fs, Window = hamming(0.04 * fs, "periodic"), MergeDistance = round(0.5 * fs));
                    % 使用 detectSpeech 函數檢測語音段，設定窗函數為漢明窗，合併距離為0.5秒

                    [row1, col1] = size(idx);  % 獲取偵測結果的尺寸
                    if row1 >= 1  % 如果檢測到語音段
                        end1 = idx(row1, 2);  % 獲取最後一個語音段的結束點
                        init2 = length(speech);  % 獲取音訊的總長度
                        len1 = init2 - end1;  % 計算語音段後面的剩餘部分長度

                        if len1 >= 0.1 * fs  % 如果語音段後的剩餘部分長度超過0.1秒
                            rob.keyRelease(KeyEvent.VK_F2);  % 模擬釋放F2鍵
                            fprintf('放開F2\n');  % 輸出釋放F2的訊息到控制台
                            app.Label1.Text = '放開F2';  % 更新應用程式中的標籤文字
                            F2_flag = 0;  % 重置F2鍵標記
                            pause(0.01);  % 暫停0.01秒

                            rob.keyPress(KeyEvent.VK_ENTER);  % 模擬按下Enter鍵
                            pause(0.3);  % 暫停0.3秒
                            rob.keyRelease(KeyEvent.VK_ENTER);  % 模擬釋放Enter鍵
                            pause(0.3);  % 暫停0.3秒

                            w = app.SpeechRecognitionEditField.Value;  % 獲取語音識別結果文本
                            fprintf('%s\n', w);  % 輸出識別結果到控制台

                            if ~isempty(w)  % 如果識別結果不為空
                                app.WordLabel.Text = w;  % 將識別結果顯示在應用程式中
                                utf8Encoded = unicode2native(w, 'UTF-8');  % 將識別結果轉換為UTF-8編碼
                                fwrite(s, utf8Encoded, 'uint8');  % 將UTF-8編碼結果通過串列埠發送
                                fprintf(s, '.');  % 發送結束標記到串列埠
                            end

                            app.SpeechRecognitionEditField.Value = '';  % 清空語音識別輸入框

                            stop(recObj);  % 停止錄音
                            recObj = audiorecorder(fs, nBits, nChannels, ID);  % 重置錄音物件
                        end

                        % 遍歷所有檢測到的語音段，標記語音位置
                        for cnt1 = 1:row1
                            init1 = idx(cnt1, 1);  % 語音段起始點
                            end1 = idx(cnt1, 2);  % 語音段結束點
                            result(init1:end1) = 1;  % 標記語音段
                        end
                    end
                end
            end

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [172 354 263 118];

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.UIFigure);
            title(app.UIAxes2, 'Title')
            xlabel(app.UIAxes2, 'X')
            ylabel(app.UIAxes2, 'Y')
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.Position = [172 233 263 122];

            % Create STARTButton
            app.STARTButton = uibutton(app.UIFigure, 'push');
            app.STARTButton.ButtonPushedFcn = createCallbackFcn(app, @STARTButtonPushed, true);
            app.STARTButton.FontSize = 14;
            app.STARTButton.Position = [147 54 100 25];
            app.STARTButton.Text = 'START';

            % Create STOPButton
            app.STOPButton = uibutton(app.UIFigure, 'push');
            app.STOPButton.ButtonPushedFcn = createCallbackFcn(app, @STOPButtonPushed, true);
            app.STOPButton.FontSize = 14;
            app.STOPButton.Position = [355 54 100 25];
            app.STOPButton.Text = 'STOP';

            % Create WordLabel
            app.WordLabel = uilabel(app.UIFigure);
            app.WordLabel.FontSize = 14;
            app.WordLabel.Position = [161 123 251 22];
            app.WordLabel.Text = 'Word';

            % Create SpeechRecognitionEditFieldLabel
            app.SpeechRecognitionEditFieldLabel = uilabel(app.UIFigure);
            app.SpeechRecognitionEditFieldLabel.HorizontalAlignment = 'right';
            app.SpeechRecognitionEditFieldLabel.FontSize = 14;
            app.SpeechRecognitionEditFieldLabel.Position = [147 154 133 22];
            app.SpeechRecognitionEditFieldLabel.Text = 'Speech Recognition';

            % Create SpeechRecognitionEditField
            app.SpeechRecognitionEditField = uieditfield(app.UIFigure, 'text');
            app.SpeechRecognitionEditField.FontSize = 14;
            app.SpeechRecognitionEditField.Position = [296 154 238 22];

            % Create Label1
            app.Label1 = uilabel(app.UIFigure);
            app.Label1.Position = [31 212 179 22];
            app.Label1.Text = 'Label1';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = app_detect0901

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
