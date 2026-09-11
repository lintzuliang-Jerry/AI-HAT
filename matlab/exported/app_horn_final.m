classdef app_horn_final < matlab.apps.AppBase

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
            global s;

            %% 初始化
            app.WordLabel.Text = '';

            import java.awt.*;
            import java.awt.event.*;



            % 建立一個Robot對象來模擬鍵盤按鍵
            rob = Robot;

            % 載入YAMNet模型---
            YAMNetLocation = 'D:\voice';

            addpath(fullfile(YAMNetLocation,'yamnet'));
            [net, classNames] = audioPretrainedNetwork("yamnet");

            % 音訊設定
            fs = 44100; % 原始採樣率

            nBits = 16;
            nChannels = 1;
            ID = -1; % -1 為預設音訊輸入裝置
            recObj = audiorecorder(fs, nBits, nChannels, ID);
            recordDuration = 1.1; % 設定錄音時長---1.5

            % 無限循環
            frame_size=512;
            speech_flag=0;
            F2_flag=0;

            %% 主迴圈
            while true
                % 聚焦到語音識別輸入框並清空
                focus(app.SpeechRecognitionEditField);
                if F2_flag==0
                    rob.keyPress(KeyEvent.VK_F2); %產生鍵盤按F2鍵
                end

                % 檢查並建立串列埠連接
                if isempty(s)
                    s = serialport("COM5", 9600);
                    fopen(s);
                end

                % 錄音
                record(recObj);

                pause(recordDuration);
                % pause(1);
                speech = getaudiodata(recObj);
                speech = speech/max(abs(speech));

                %% 喇叭聲音判斷
                if(length(speech)>=44100)
                    % 使用YAMNet進行預測
                    spectrograms = yamnetPreprocess(speech, fs);
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

                    if hornDetectedThisTime == 1
                        app.WordLabel.Text = "小心有車靠近";
                        utf8Encoded = unicode2native("小心有車靠近.", 'UTF-8');
                        fwrite(s, utf8Encoded, 'uint8');
                    end
                end
                %% 語音判斷
                len_speech = length(speech);
                frame_no=len_speech/frame_size;

                egy_mat=zeros(1,frame_no);
                for cnt3=1:frame_no
                    init1=(cnt3-1)*frame_size+1;
                    end1=cnt3*frame_size;
                    frame1=speech(init1:end1);
                    egy=10*log10(frame1'*frame1);
                    egy_mat(cnt3)=egy;
                end
                result=0*speech;
                speech_frame=sum(egy_mat>-5);   %%%%%%
                background_frame=sum(egy_mat<=0);%%%%%%%
                if speech_frame>=5
                    speech_flag=1;
                end
                app.Label1.Text='';
                if speech_flag==1 && background_frame>=5 %10
                    speech_flag=0;
                    idx=detectSpeech(speech,fs,Window=hamming(0.04*fs,"periodic"),MergeDistance=round(0.5*fs));
                    [row1,col1]=size(idx);
                    if row1>=1
                        end1=idx(row1,2);
                        init2=length(speech);
                        len1=init2-end1;
                        if len1>=0.1*fs
                            %if len1>=200
                            rob.keyRelease(KeyEvent.VK_F2); %放開F2
                            fprintf('放開F2\n');
                            app.Label1.Text='放開F2';
                            F2_flag=0;
                            pause(0.01);

                            rob.keyPress(KeyEvent.VK_ENTER);
                            pause(0.3);
                            rob.keyRelease(KeyEvent.VK_ENTER);
                            pause(0.3);

                            w = app.SpeechRecognitionEditField.Value
                            fprintf('%s\n',w);

                            if ~isempty(w)
                                app.WordLabel.Text = w;
                                utf8Encoded = unicode2native(w, 'UTF-8');
                                fwrite(s, utf8Encoded, 'uint8');
                                fprintf(s, '.');
                            end


                            %%

                            % drawnow;
                            %focus(app.WordLabel);


                            % app.WordLabel.Text = app.SpeechRecognitionEditField.Value;
                            app.SpeechRecognitionEditField.Value = '';

                            % pause(0.01);

                            stop(recObj);
                            recObj = audiorecorder(fs, nBits, nChannels, ID);

                        end
                        %result=0*speech;
                        for cnt1=1:row1
                            init1=idx(cnt1,1);
                            end1=idx(cnt1,2);
                            result(init1:end1)=1;
                        end
                    end
                end
            end

            app.WordLabel.Text = '測試結束';
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
        function app = app_horn_final

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
