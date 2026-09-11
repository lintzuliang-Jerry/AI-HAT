classdef app2 < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure     matlab.ui.Figure
        ButtonGroup  matlab.ui.container.ButtonGroup
        Button_5     matlab.ui.control.RadioButton
        Button_4     matlab.ui.control.RadioButton
        Button_3     matlab.ui.control.RadioButton
        EditField    matlab.ui.control.EditField
        Label_3      matlab.ui.control.Label
        Label_2      matlab.ui.control.Label
        OLEDLabel    matlab.ui.control.Label
        Button_2     matlab.ui.control.Button
        Button       matlab.ui.control.Button
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: Button_2
        function Button_2Pushed(app, event)
            delete(app);
        end

        % Button pushed function: Button
        function ButtonPushed(app, event)
            app.Label_2.Text = '';
            import java.awt.*;
            import java.awt.event.*;

            %Create a Robot-object to do the key-pressing
            rob=Robot;
            % rob.keyPress(KeyEvent.VK_F2); %產生鍵盤按F2鍵
            %rob.keyRelease(KeyEvent.VK_F


            % 2);%放開F2
            cnt1=0;
            %while cnt1<20
            while 1

                focus(app.EditField);
                app.EditField.Value='';
                cnt2=0;
                rob.keyPress(KeyEvent.VK_F2); %產生鍵盤按F2鍵
                while cnt2<=1
                    cnt2=cnt2+1;
                    pause(0.1);
                end
                rob.keyRelease(KeyEvent.VK_F2);%放開F2

                %             if i>=5 % 講話一句話停頓，就將文字存取
                rob.keyPress(KeyEvent.VK_ENTER);
                rob.keyRelease(KeyEvent.VK_ENTER);
                pause(0.01);

                %                 end
                w= app.EditField.Value;
                w
                if length(w)>0
                    app.Label_2.Text=w;
                end

                cnt1=cnt1+1;
                if ~exist('s')
                    s = serialport("COM3",9600);  % insert your serial
                    fopen(s);
                end

                %                 w = app.Label_2.Text;


                %pause(2);


                if length(w)>0
                    fprintf(s,'%s',convertStringsToChars(w));
                    fprintf(s,'.');



                    %pause(20);%--------------
                end

            end
            app.Label_2.Text='測試結束';



        end

        % Selection changed function: ButtonGroup
        function ButtonGroupSelectionChanged(app, event)
            selectedButton = app.ButtonGroup.SelectedObject;
            if app.Button_3.Value   %where "Button1" is the name of the first radio button
                LiVal = 0;
            elseif app.Button_4.Value
                LiVal = 80;
            else
                LiVal = 255;
            end
            if ~exist('s')
                s = serialport("COM3",9600);  % insert your serial
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

            % Create Button
            app.Button = uibutton(app.UIFigure, 'push');
            app.Button.ButtonPushedFcn = createCallbackFcn(app, @ButtonPushed, true);
            app.Button.Position = [465 404 100 23];
            app.Button.Text = '開始';

            % Create Button_2
            app.Button_2 = uibutton(app.UIFigure, 'push');
            app.Button_2.ButtonPushedFcn = createCallbackFcn(app, @Button_2Pushed, true);
            app.Button_2.Position = [465 340 100 23];
            app.Button_2.Text = '結束';

            % Create OLEDLabel
            app.OLEDLabel = uilabel(app.UIFigure);
            app.OLEDLabel.Position = [59 357 74 22];
            app.OLEDLabel.Text = 'OLED輸出：';

            % Create Label_2
            app.Label_2 = uilabel(app.UIFigure);
            app.Label_2.Position = [139 316 259 63];

            % Create Label_3
            app.Label_3 = uilabel(app.UIFigure);
            app.Label_3.HorizontalAlignment = 'right';
            app.Label_3.Position = [59 412 65 22];
            app.Label_3.Text = '辨識結果：';

            % Create EditField
            app.EditField = uieditfield(app.UIFigure, 'text');
            app.EditField.Position = [139 412 100 22];

            % Create ButtonGroup
            app.ButtonGroup = uibuttongroup(app.UIFigure);
            app.ButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @ButtonGroupSelectionChanged, true);
            app.ButtonGroup.TitlePosition = 'centertop';
            app.ButtonGroup.Title = '螢幕亮度';
            app.ButtonGroup.Position = [77 188 123 106];

            % Create Button_3
            app.Button_3 = uiradiobutton(app.ButtonGroup);
            app.Button_3.Text = '稍暗';
            app.Button_3.Position = [11 60 58 22];
            app.Button_3.Value = true;

            % Create Button_4
            app.Button_4 = uiradiobutton(app.ButtonGroup);
            app.Button_4.Text = '適中';
            app.Button_4.Position = [11 38 65 22];

            % Create Button_5
            app.Button_5 = uiradiobutton(app.ButtonGroup);
            app.Button_5.Text = '明亮';
            app.Button_5.Position = [11 16 65 22];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = app2

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
