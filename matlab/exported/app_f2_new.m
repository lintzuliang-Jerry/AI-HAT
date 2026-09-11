classdef app_f2_new < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        AIHATLabel                     matlab.ui.control.Label
        BrightnessContrastButtonGroup  matlab.ui.container.ButtonGroup
        BrightButton                   matlab.ui.control.RadioButton
        MediumButton_2                 matlab.ui.control.RadioButton
        DarkButton                     matlab.ui.control.RadioButton
        SpeechRecognitionEditField     matlab.ui.control.EditField
        Label_3                        matlab.ui.control.Label
        WordLabel                      matlab.ui.control.Label
        OLEDOutputLabel                matlab.ui.control.Label
        STOPButton                     matlab.ui.control.Button
        STARTButton                    matlab.ui.control.Button
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: STOPButton
        function STOPButtonPushed(app, event)
            delete(app);
        end

        % Button pushed function: STARTButton
        function STARTButtonPushed(app, event)

            global s;

            % 清空文字標籤
            app.WordLabel.Text = '';

            import java.awt.*;
            import java.awt.event.*;

            % 建立一個Robot對象來模擬鍵盤按鍵
            rob = Robot;

            % 設置參數 -----
            fs = 44100; % 採樣率
            frameLength = 0.5; % 幀長度（秒）
            frameSize = round(fs * frameLength); % 每幀的採樣點數
            historyDuration = 10; % 歷史記錄持續時間（秒）
            bufferSize = round(fs * historyDuration); % 緩衝區大小（10秒的數據）
            flag1 = 0;
            flag2 = 0;
            flag3 = 0;
            isKeyPressed = false; % 新增變量來追踪按鍵狀態

            % 初始化音頻設備讀取器
            audioReader = audioDeviceReader('SampleRate', fs, 'SamplesPerFrame', frameSize);

            % 初始化緩衝區 ------
            buffer = zeros(bufferSize, 1);
            detectionBuffer = zeros(bufferSize, 1);

            oldrow = 0;

            % 無限循環
            while true
                % 聚焦到語音識別輸入框並清空
                focus(app.SpeechRecognitionEditField);
                app.SpeechRecognitionEditField.Value = '';



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
                            % disp('語音信號開始');
                            % 按下F2鍵
                            rob.keyPress(KeyEvent.VK_F2);
                            isKeyPressed = true;
                        end
                        flag1 = size(idx, 1);
                        flag3 = 1;
                    elseif flag2 == idx(end,2) - idx(end,1)
                        if flag3 == 1
                            % disp('語音信號結束');
                            % 釋放F2鍵
                            if isKeyPressed
                                rob.keyRelease(KeyEvent.VK_F2);
                                isKeyPressed = false;


                                % 模擬按下並釋放 Enter 鍵
                                rob.keyPress(KeyEvent.VK_ENTER);
                                rob.keyRelease(KeyEvent.VK_ENTER);
                                pause(0.01);pause(0.5);


                                % 讀取語音識別結果
                                w = app.SpeechRecognitionEditField.Value;


                                % 檢查並建立串列埠連接
                                if isempty(s)
                                    s = serialport("COM10", 9600);
                                    fopen(s);
                                end

                                % 將語音識別結果寫入串列埠
                                if ~isempty(w)
                                    app.WordLabel.Text = w;
                                    utf8Encoded = unicode2native(w, 'UTF-8');
                                    fwrite(s, utf8Encoded, 'uint8');
                                    fprintf(s, '.');
                                end


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

            app.WordLabel.Text = '測試結束';



        end

        % Selection changed function: BrightnessContrastButtonGroup
        function BrightnessContrastButtonGroupSelectionChanged(app, event)
            global s;
            %lobal LiVal;
            selectedButton = app.BrightnessContrastButtonGroup.SelectedObject;
            if app.DarkButton.Value   %where "Button1" is the name of the first radio button
                LiVal = 0;
            elseif app.MediumButton_2.Value
                LiVal = 80;
            else
                LiVal = 255;


            end
            if isempty(s)
            %if ~exist('s')
                s = serialport("COM5",9600);  % insert your serial
                fopen(s);


            end
            pause(2);
            fprintf('LiVal=%g\n',LiVal);
            fprintf(s,'%s',LiVal);


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

            % Create STARTButton
            app.STARTButton = uibutton(app.UIFigure, 'push');
            app.STARTButton.ButtonPushedFcn = createCallbackFcn(app, @STARTButtonPushed, true);
            app.STARTButton.FontSize = 14;
            app.STARTButton.Position = [453 321 100 25];
            app.STARTButton.Text = 'START';

            % Create STOPButton
            app.STOPButton = uibutton(app.UIFigure, 'push');
            app.STOPButton.ButtonPushedFcn = createCallbackFcn(app, @STOPButtonPushed, true);
            app.STOPButton.FontSize = 14;
            app.STOPButton.Position = [454 262 100 25];
            app.STOPButton.Text = 'STOP';

            % Create OLEDOutputLabel
            app.OLEDOutputLabel = uilabel(app.UIFigure);
            app.OLEDOutputLabel.FontSize = 14;
            app.OLEDOutputLabel.Position = [83 263 97 22];
            app.OLEDOutputLabel.Text = '  OLED Output';

            % Create WordLabel
            app.WordLabel = uilabel(app.UIFigure);
            app.WordLabel.FontSize = 14;
            app.WordLabel.Position = [232 263 213 22];
            app.WordLabel.Text = 'Word';

            % Create Label_3
            app.Label_3 = uilabel(app.UIFigure);
            app.Label_3.HorizontalAlignment = 'right';
            app.Label_3.FontSize = 14;
            app.Label_3.Position = [82 322 133 22];
            app.Label_3.Text = 'Speech Recognition';

            % Create SpeechRecognitionEditField
            app.SpeechRecognitionEditField = uieditfield(app.UIFigure, 'text');
            app.SpeechRecognitionEditField.FontSize = 14;
            app.SpeechRecognitionEditField.Position = [231 322 111 22];

            % Create BrightnessContrastButtonGroup
            app.BrightnessContrastButtonGroup = uibuttongroup(app.UIFigure);
            app.BrightnessContrastButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @BrightnessContrastButtonGroupSelectionChanged, true);
            app.BrightnessContrastButtonGroup.TitlePosition = 'centertop';
            app.BrightnessContrastButtonGroup.Title = 'Brightness Contrast';
            app.BrightnessContrastButtonGroup.FontSize = 14;
            app.BrightnessContrastButtonGroup.Position = [83 102 471 106];

            % Create DarkButton
            app.DarkButton = uiradiobutton(app.BrightnessContrastButtonGroup);
            app.DarkButton.Text = 'Dark';
            app.DarkButton.FontSize = 14;
            app.DarkButton.Position = [56 37 54 22];
            app.DarkButton.Value = true;

            % Create MediumButton_2
            app.MediumButton_2 = uiradiobutton(app.BrightnessContrastButtonGroup);
            app.MediumButton_2.Text = 'Medium';
            app.MediumButton_2.FontSize = 14;
            app.MediumButton_2.Position = [204 37 72 22];

            % Create BrightButton
            app.BrightButton = uiradiobutton(app.BrightnessContrastButtonGroup);
            app.BrightButton.Text = 'Bright';
            app.BrightButton.FontSize = 14;
            app.BrightButton.Position = [352 37 76 22];

            % Create AIHATLabel
            app.AIHATLabel = uilabel(app.UIFigure);
            app.AIHATLabel.FontSize = 24;
            app.AIHATLabel.FontWeight = 'bold';
            app.AIHATLabel.Position = [280 392 83 31];
            app.AIHATLabel.Text = 'AI HAT';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = app_f2_new

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
