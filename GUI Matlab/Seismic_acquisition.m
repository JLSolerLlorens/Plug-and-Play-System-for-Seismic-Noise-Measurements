function varargout = Seismic_acquisition(varargin)

%       SEISMIC_ACQUISITION 
%
%       Configuration of the seismic acquisition system based on Arduino Due
%       and real-time monitoring of the recorded seismic noise
%
%       Seismic_Acquisition;
%       
%      
%       The function Seismic_Acquisition displays a graphical user
%       interface (GUI) which allows the user to configure the acquisition  
%       and recording of seismic noise through the Arduino Due.
%       The configuration file is saved in the computer as "current_setup.mat',
%       as well as in the SD card of the Arduino shield.
%        
%       When the developed hardware system is acquiring seismic noise, 
%       the GUI also shows in real-time the registering signals, together  
%       with the corresponding RMS value. 
%       
%       The obtained data are saved as binary MAT file (*.mat) and 
%       SESAME ASCII Format (*.saf). 
%
%
%       Last Modified by GUIDE v2.5 02-Aug-2019 11:18:50
%       Last Revision: 31-July-2019.



%*************************************************************************%
%                BEGIN initialization code - DO NOT EDIT                  %
%                ----------------------------------------                 %
%*************************************************************************%


gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Seismic_acquisition_OpeningFcn, ...
                   'gui_OutputFcn',  @Seismic_acquisition_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end


%*************************************************************************%
%                END initialization code - DO NOT EDIT                    %
%                -------------------------------------                    %
%*************************************************************************%


%*************************************************************************%
%                BEGIN Opening Function                                   %
%                ----------------------                                   %
%*************************************************************************%


% --- Executes just before Seismic_acquisition is made visible.
function Seismic_acquisition_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Seismic_acquisition (see VARARGIN)

% Choose default command line output for Seismic_acquisition
handles.output = hObject;

% Variable used for stoping the acquisition process
global stop_acquisition;
stop_acquisition=0;

%
% Website of the research group
%

% Create and display the text label
url = 'https://web.ua.es/en/girs/';
labelStr = ['<html><a href=""><FONT SIZE=2>' url '</FONT></a></html>'];

jLabel = javaObjectEDT('javax.swing.JLabel', labelStr);
[hjLabel,hContainer] = javacomponent(jLabel, [28,10,300,20], gcf);
 
% Modify the mouse cursor when hovering on the label
hjLabel.setCursor(java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.HAND_CURSOR));
 
% Set the label's tooltip
hjLabel.setToolTipText(['Visit the ' url ' website']);
 
% Set the mouse-click callback
set(hjLabel, 'MouseClickedCallback', @(h,e)web(url, '-browser'))

% Show main image
axis(handles.axes1);
imshow('Logo.png');
  
%
% Hide RMS text
%

set(handles.RMS_text,'String','');

set(handles.rms_1,'String','');
set(handles.rms_2,'String','');
set(handles.rms_3,'String','');
set(handles.rms_4,'String','');
set(handles.rms_5,'String','');
set(handles.rms_6,'String','');
set(handles.rms_7,'String','');
set(handles.rms_8,'String','');
set(handles.rms_9,'String','');
set(handles.rms_10,'String','');
set(handles.rms_11,'String','');
set(handles.rms_12,'String','');

set(handles.V_1,'String','');
set(handles.V_2,'String','');
set(handles.V_3,'String','');
set(handles.V_4,'String','');
set(handles.V_5,'String','');
set(handles.V_6,'String','');
set(handles.V_7,'String','');
set(handles.V_8,'String','');
set(handles.V_9,'String','');
set(handles.V_10,'String','');
set(handles.V_11,'String','');
set(handles.V_12,'String','');

%
% Serial ports
%

if isempty(instrfind)==0
    fclose(instrfind);
end

serialInfo = instrhwinfo('serial');
serial_values2=serialInfo.AvailableSerialPorts;
serial_values(1,1)={'None'};
    
%
% Enable all the options
%

handles=Enable_options(hObject,handles,'on');

%
% Set the different parameters of the acquisition process
%

% Serial ports
serial_values(2:1+length(serial_values2),1)=serial_values2;
handles.serial_values=serial_values;

set(handles.Serial_port_edit,'String',serial_values);
set(handles.Serial_port_edit,'Value',1);

serial_port_name=serial_values(1);
handles.serial_port_name=serial_port_name;

% Sampling frequency
handles.sampling_frequency_values={100,125,200,250}; 
handles.sampling_frequency=cell2mat(handles.sampling_frequency_values(2));
set(handles.Sampling_frequency_edit,'String',handles.sampling_frequency_values);
set(handles.Sampling_frequency_edit,'Value',1);

% Voltage gain
handles.voltage_gain_values={1,2,4};
handles.voltage_gain=cell2mat(handles.voltage_gain_values(2));

set(handles.Voltage_gain_edit,'String',handles.voltage_gain_values);
set(handles.Voltage_gain_edit,'Value',2);

% Voltage conversion
% Default values for Arduino DUE
handles.dynamic_range=3.3; 
set(handles.Dynamic_range_edit,'String',num2str(handles.dynamic_range));

handles.voltage_levels=4096; 
set(handles.Voltage_levels_edit,'String',num2str(handles.voltage_levels));

% Duration
handles.duration=1; % 1 minute by default
handles.maximum_duration=120; % 120 minute maximum
handles.minimum_duration=1;   % 1 minute minimum
set(handles.Duration_edit,'String',num2str(handles.duration));

% Channels
handles.channel_1=0;
handles.channel_2=1;
handles.channel_3=0;
handles.channel_4=0;
handles.channel_5=1;
handles.channel_6=0;
handles.channel_7=0;
handles.channel_8=1;
handles.channel_9=0;
handles.channel_10=0;
handles.channel_11=0;
handles.channel_12=0;

set(handles.Channel_1,'Value',handles.channel_1);
set(handles.Channel_2,'Value',handles.channel_2);
set(handles.Channel_3,'Value',handles.channel_3);
set(handles.Channel_4,'Value',handles.channel_4);
set(handles.Channel_5,'Value',handles.channel_5);
set(handles.Channel_6,'Value',handles.channel_6);
set(handles.Channel_7,'Value',handles.channel_7);
set(handles.Channel_8,'Value',handles.channel_8);
set(handles.Channel_9,'Value',handles.channel_9);
set(handles.Channel_10,'Value',handles.channel_10);
set(handles.Channel_11,'Value',handles.channel_11);
set(handles.Channel_12,'Value',handles.channel_12);

% Save file in PC
handles.pc=1; % Save to PC
set(handles.Save_to_PC,'Value',handles.pc);

% Save file in SD
handles.sd=1; % Save to SD Arduino
set(handles.Save_to_SD,'Value',handles.sd);

% Selected directory
handles.selected_directory_online=pwd;
set(handles.Selected_directory_edit,'String',handles.selected_directory_online);

% Selected file name
current_date=regexprep(datestr(now),'-','');
current_date=regexprep(current_date,':','');
current_date=regexprep(current_date,' ','_');

current_site='Site';

current_name=[current_site,'_',current_date];

handles.selected_date=current_date;
handles.selected_site=current_site;

handles.selected_file_name=current_name;
set(handles.Selected_date,'String',handles.selected_date);
set(handles.Selected_site,'String',handles.selected_site);

% Update the acquisition parameters with the last one used
% in case that they were available in the 'current_setup.mat' file

if exist('current_setup.mat')~=0

    load current_setup.mat

    % Available serial ports

    serialInfo = instrhwinfo('serial');
    serial_values2=serialInfo.AvailableSerialPorts;
    serial_values(1,1)={'None'};
    serial_values(2:1+ length(serial_values2),1)=serial_values2;
    handles.serial_values=serial_values;

    set(handles.Serial_port_edit,'String',serial_values);

    d=(strcmp((serial_values),current_setup.serial_port_name));

    if sum(d)==0
        set(handles.Serial_port_edit,'Value',1);
        serial_port_name=serial_values(1);
        handles.serial_port_name=serial_port_name;
    else
        handles.serial_port_name=current_setup.serial_port_name;
        indx=find(d==1);
        set(handles.Serial_port_edit,'Value',indx);

    end

    % Connect with serial port (1 -> Open)
    handles=Connect_serial_port(hObject,handles,'1');

    % Send USB command to Arduino
    handles=Send_command(hObject,handles,'USB');

    % Sampling frequency
    handles.sampling_frequency=current_setup.sampling_frequency;
    indx=find(cell2mat(handles.sampling_frequency_values)==handles.sampling_frequency);
    if isempty(indx)==1
        indx=1; % By default 100 Hz
    end
    set(handles.Sampling_frequency_edit,'Value',indx);

    % Voltage gain
    handles.voltage_gain=current_setup.voltage_gain;
    indx=find(cell2mat(handles.voltage_gain_values)==handles.voltage_gain);
    set(handles.Voltage_gain_edit,'Value',indx);

    % Duration
    handles.duration=current_setup.duration;
    set(handles.Duration_edit,'String',num2str(handles.duration));

    % Channels
    handles.channel_1=current_setup.channel_1;
    handles.channel_2=current_setup.channel_2;
    handles.channel_3=current_setup.channel_3;
    handles.channel_4=current_setup.channel_4;
    handles.channel_5=current_setup.channel_5;
    handles.channel_6=current_setup.channel_6;
    handles.channel_7=current_setup.channel_7;
    handles.channel_8=current_setup.channel_8;
    handles.channel_9=current_setup.channel_9;
    handles.channel_10=current_setup.channel_10;
    handles.channel_11=current_setup.channel_11;
    handles.channel_12=current_setup.channel_12;

    set(handles.Channel_1,'Value',handles.channel_1);
    set(handles.Channel_2,'Value',handles.channel_2);
    set(handles.Channel_3,'Value',handles.channel_3);
    set(handles.Channel_4,'Value',handles.channel_4);
    set(handles.Channel_5,'Value',handles.channel_5);
    set(handles.Channel_6,'Value',handles.channel_6);
    set(handles.Channel_7,'Value',handles.channel_7);
    set(handles.Channel_8,'Value',handles.channel_8);
    set(handles.Channel_9,'Value',handles.channel_9);
    set(handles.Channel_10,'Value',handles.channel_10);
    set(handles.Channel_11,'Value',handles.channel_11);
    set(handles.Channel_12,'Value',handles.channel_12);

    % Verify the maximum sampling frequency allowed for the number of the 
    % selected channels
    guidata(hObject, handles);
    handles=Verify_sampling_frequency(hObject,handles);
    guidata(hObject, handles);

    % Save file in PC
    handles.pc=current_setup.pc; 
    set(handles.Save_to_PC,'Value',handles.pc);

    % Save file in SD
    handles.sd=current_setup.sd; 
    set(handles.Save_to_SD,'Value',handles.sd);

    % Selected directory
    selected_directory_online=handles.selected_directory_online;

    handles.selected_directory_online=current_setup.selected_directory_online;

    if exist(handles.selected_directory_online)==0
        handles.selected_directory_online=selected_directory_online;
    end

    set(handles.Selected_directory_edit,'String',handles.selected_directory_online);

    % The file name in not changed
    handles.selected_site=current_setup.selected_site;
    set(handles.Selected_date,'String',handles.selected_date);      
    set(handles.Selected_site,'String',handles.selected_site);

end

    
if isempty(serial_values2)==1
    % If no serial port is found, then it will show the port 'None'
    % and disable the other options
    set(handles.Serial_port_edit,'String',serial_values);
    set(handles.Serial_port_edit,'Value',1);
    
    % Disable options
    handles=Enable_options(hObject,handles,'off');


end
 
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Seismic_acquisition wait for user response (see UIRESUME)
uiwait(handles.figure1);

%*************************************************************************%
%                END Opening Function                                     %
%                --------------------                                     %
%*************************************************************************%

%*************************************************************************%
%           BEGIN CloseRequestFcn Function                                %
%           ------------------------------                                %
%*************************************************************************%

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Save the current acquisition parameters in the current_setup.mat
current_setup.serial_port_name=handles.serial_port_name;
current_setup.sampling_frequency=handles.sampling_frequency;
current_setup.voltage_gain=handles.voltage_gain;
current_setup.dynamic_range=handles.dynamic_range;
current_setup.voltage_levels=handles.voltage_levels;
current_setup.duration=handles.duration;

current_setup.channel_1=handles.channel_1;
current_setup.channel_2=handles.channel_2;
current_setup.channel_3=handles.channel_3;
current_setup.channel_4=handles.channel_4;
current_setup.channel_5=handles.channel_5;
current_setup.channel_6=handles.channel_6;
current_setup.channel_7=handles.channel_7;
current_setup.channel_8=handles.channel_8;
current_setup.channel_9=handles.channel_9;
current_setup.channel_10=handles.channel_10;
current_setup.channel_11=handles.channel_11;
current_setup.channel_12=handles.channel_12;

current_setup.pc=handles.pc;
current_setup.sd=handles.sd;

current_setup.selected_directory_online=handles.selected_directory_online;

current_setup.selected_site=handles.selected_site;

save current_setup.mat current_setup;


% Hint: delete(hObject) closes the figure
delete(hObject);

%*************************************************************************%
%           END CloseRequestFcn Function                                  %
%           -----------------------------                                 %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Seismic_acquisition output Function                     %
%           ------------------------------------------                    %
%*************************************************************************%

% --- Outputs from this function are returned to the command line.
function varargout = Seismic_acquisition_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA


% Get default command line output from handles structure
varargout{1} = 1;

%*************************************************************************%
%           END Seismic_acquisition output Function                       %
%           -----------------------------------------                     %
%*************************************************************************%

%*************************************************************************%
%*************************************************************************%
%                                                                         %
%           PANNEL Acquisition setup                                      %
%           ------------------------                                      %
%                                                                         %
%*************************************************************************%
%*************************************************************************%

%*************************************************************************%
%           BEGIN Serial_port_edit CreateFcn                              %
%           --------------------------------                              %
%*************************************************************************%

% --- Executes during object creation, after setting all properties.
function Serial_port_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Serial_port_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%*************************************************************************%
%           END Serial_port_edit CreateFcn                                %
%           ------------------------------                                %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Serial_port_edit Callback                               %
%           -------------------------------                               %
%*************************************************************************%

% --- Executes on selection change in Serial_port_edit.
function Serial_port_edit_Callback(hObject, eventdata, handles)
% hObject    handle to Serial_port_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Serial_port_edit contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Serial_port_edit


% Serial ports
current_value=get(handles.Serial_port_edit,'Value');
serial_port_name=handles.serial_values(current_value);
handles.serial_port_name=serial_port_name;

% Update handles structure
guidata(hObject, handles);

% Connect with series port (1 -> Open)
handles=Connect_serial_port(hObject,handles,'1');

% Send USB command to Arduino
handles=Send_command(hObject,handles,'USB');

% Update handles structure
guidata(hObject, handles);

        
%*************************************************************************%
%           END Serial_port_edit Callback                                 %
%           -----------------------------                                 %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Refresh_port Callback                                   %
%           ---------------------------                                   %
%*************************************************************************%

% --- Executes on button press in Refresh_port.
function Refresh_port_Callback(hObject, eventdata, handles)
% hObject    handle to Refresh_port (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Serial ports

if isempty(instrfind)==0
    fclose(instrfind);
end

serialInfo = instrhwinfo('serial');
serial_values2=serialInfo.AvailableSerialPorts;
serial_values(1,1)={'None'};
serial_values(2:1+ length(serial_values2),1)=serial_values2;
handles.serial_values=serial_values;

set(handles.Serial_port_edit,'String',serial_values);

% Update handles structure
guidata(hObject, handles);

%*************************************************************************%
%           END Refresh_port Callback                                     %
%           ---------------------------                                   %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Sampling_frequency_edit CreateFcn                       %
%           ---------------------------------------                       %
%*************************************************************************%

% --- Executes during object creation, after setting all properties.
function Sampling_frequency_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Sampling_frequency_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%*************************************************************************%
%           END Sampling_frequency_edit CreateFcn                         %
%           -------------------------------------                         %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Sampling_frequency_edit Callback                        %
%           --------------------------------------                        %
%*************************************************************************%

% --- Executes on selection change in Sampling_frequency_edit.
function Sampling_frequency_edit_Callback(hObject, eventdata, handles)
% hObject    handle to Sampling_frequency_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Sampling_frequency_edit contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Sampling_frequency_edit

current_value=get(handles.Sampling_frequency_edit,'Value');
handles.sampling_frequency=cell2mat(handles.sampling_frequency_values(current_value));

% Update handles structure
guidata(hObject, handles);

%*************************************************************************%
%           END Sampling_frequency_edit Callback                          %
%           ------------------------------------                          %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Voltage_gain_edit CreateFcn                             %
%           ---------------------------------                             %
%*************************************************************************%

% --- Executes during object creation, after setting all properties.
function Voltage_gain_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Voltage_gain_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%*************************************************************************%
%           END Voltage_gain_edit CreateFcn                               %
%           -------------------------------                               %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Voltage_gain_edit Callback                              %
%           --------------------------------                              %
%*************************************************************************%

% --- Executes on selection change in Voltage_gain_edit.
function Voltage_gain_edit_Callback(hObject, eventdata, handles)
% hObject    handle to Voltage_gain_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Voltage_gain_edit contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Voltage_gain_edit

current_value=get(handles.Voltage_gain_edit,'Value');
handles.voltage_gain=cell2mat(handles.voltage_gain_values(current_value));

% Update handles structure
guidata(hObject, handles);


%*************************************************************************%
%           END Voltage_gain_edit Callback                                %
%           ------------------------------                                %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Dynamic_range_edit CreateFcn                       %
%           ---------------------------------------                       %
%*************************************************************************%

% --- Executes during object creation, after setting all properties.
function Dynamic_range_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Dynamic_range_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%*************************************************************************%
%           END Dynamic_range_edit CreateFcn                         %
%           -------------------------------------                         %
%*************************************************************************%


%*************************************************************************%
%           BEGIN Dynamic_range_edit Callback                             %
%           ---------------------------------                             %
%*************************************************************************%

function Dynamic_range_edit_Callback(hObject, eventdata, handles)
% hObject    handle to Dynamic_range_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Dynamic_range_edit as text
%        str2double(get(hObject,'String')) returns contents of Dynamic_range_edit as a double

dynamic_range=handles.dynamic_range;

handles.dynamic_range=str2num(get(handles.Dynamic_range_edit,'String'));

if handles.dynamic_range<=0
    handles.dynamic_range=dynamic_range;
    warndlg('The dynamic range has to be higher than 0');
end

set(handles.Dynamic_range_edit,'String',num2str(handles.dynamic_range));

% Update handles structure
guidata(hObject, handles);

%*************************************************************************%
%           END Dynamic_range_edit Callback                               %
%           -------------------------------                               %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Voltage_levels_edit CreateFcn                           %
%           -----------------------------------                           %
%*************************************************************************%


% --- Executes during object creation, after setting all properties.
function Voltage_levels_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Voltage_levels_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%*************************************************************************%
%           END Voltage_levels_edit CreateFcn                             %
%           ---------------------------------                             %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Voltage_levels_edit Callback                            %
%           ----------------------------------                            %
%*************************************************************************%


function Voltage_levels_edit_Callback(hObject, eventdata, handles)
% hObject    handle to Voltage_levels_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Voltage_levels_edit as text
%        str2double(get(hObject,'String')) returns contents of Voltage_levels_edit as a double

voltage_levels=handles.voltage_levels;

handles.voltage_levels=str2num(get(handles.Voltage_levels_edit,'String'));

if handles.voltage_levels<=0
    handles.voltage_levels=voltage_levels;
    warndlg('The number of voltage levels has to be higher than 0');
end

set(handles.Voltage_levels_edit,'String',num2str(handles.voltage_levels));

% Update handles structure
guidata(hObject, handles);


%*************************************************************************%
%           END Voltage_levels_edit Callback                              %
%           --------------------------------                              %
%*************************************************************************%


%*************************************************************************%
%           BEGIN Duration_edit CreateFcn                                 %
%           -----------------------------                                 %
%*************************************************************************%

% --- Executes during object creation, after setting all properties.
function Duration_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Duration_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%*************************************************************************%
%           END Duration_edit CreateFcn                                   %
%           ---------------------------                                   %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Duration_edit Callback                                  %
%           ----------------------------                                  %
%*************************************************************************%

function Duration_edit_Callback(hObject, eventdata, handles)
% hObject    handle to Duration_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Duration_edit as text
%        str2double(get(hObject,'String')) returns contents of Duration_edit as a double

duration=handles.duration;
handles.duration=str2num(get(handles.Duration_edit,'String'));

if handles.duration<handles.minimum_duration   
    handles.duration=duration;
    warndlg(['The minimum duration allowed is ',num2str(handles.minimum_duration)]);
end

if handles.duration>handles.maximum_duration
    handles.duration=duration;
    warndlg(['The maximum duration allowed is ',num2str(handles.maximum_duration)]);
end

set(handles.Duration_edit,'String',num2str(handles.duration));


% Update handles structure
guidata(hObject, handles);


%*************************************************************************%
%           END Duration_edit Callback                                    %
%           --------------------------                                    %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Channel_n Callback                                      %
%           ---------------------------                                   %
%*************************************************************************%


% --- Executes on button press in Channel_1.
function Channel_1_Callback(hObject, eventdata, handles)
% hObject    handle to Channel_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Channel_1

handles.channel_1=get(handles.Channel_1,'Value');

% Update handles structure
guidata(hObject, handles);

% Verify the maximum sampling frequency allowed for the number of the 
% selected channels
handles=Verify_sampling_frequency(hObject,handles);
guidata(hObject, handles);

% --- Executes on button press in Channel_2.
function Channel_2_Callback(hObject, eventdata, handles)
% hObject    handle to Channel_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Channel_2

handles.channel_2=get(handles.Channel_2,'Value');

% Update handles structure
guidata(hObject, handles);

% Verify the maximum sampling frequency allowed for the number of the 
% selected channels
handles=Verify_sampling_frequency(hObject,handles);
guidata(hObject, handles);

% --- Executes on button press in Channel_3.
function Channel_3_Callback(hObject, eventdata, handles)
% hObject    handle to Channel_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Channel_3

handles.channel_3=get(handles.Channel_3,'Value');

% Update handles structure
guidata(hObject, handles);

% Verify the maximum sampling frequency allowed for the number of the 
% selected channels
handles=Verify_sampling_frequency(hObject,handles);
guidata(hObject, handles);

% --- Executes on button press in Channel_4.
function Channel_4_Callback(hObject, eventdata, handles)
% hObject    handle to Channel_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Channel_4

handles.channel_4=get(handles.Channel_4,'Value');

% Update handles structure
guidata(hObject, handles);

% Verify the maximum sampling frequency allowed for the number of the 
% selected channels
handles=Verify_sampling_frequency(hObject,handles);
guidata(hObject, handles);

% --- Executes on button press in Channel_5.
function Channel_5_Callback(hObject, eventdata, handles)
% hObject    handle to Channel_5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Channel_5

handles.channel_5=get(handles.Channel_5,'Value');

% Update handles structure
guidata(hObject, handles);

% Verify the maximum sampling frequency allowed for the number of the 
% selected channels
handles=Verify_sampling_frequency(hObject,handles);
guidata(hObject, handles);

% --- Executes on button press in Channel_6.
function Channel_6_Callback(hObject, eventdata, handles)
% hObject    handle to Channel_6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Channel_6

handles.channel_6=get(handles.Channel_6,'Value');

% Update handles structure
guidata(hObject, handles);

% Verify the maximum sampling frequency allowed for the number of the 
% selected channels
handles=Verify_sampling_frequency(hObject,handles);
guidata(hObject, handles);

% --- Executes on button press in Channel_7.
function Channel_7_Callback(hObject, eventdata, handles)
% hObject    handle to Channel_7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Channel_7

handles.channel_7=get(handles.Channel_7,'Value');

% Update handles structure
guidata(hObject, handles);

% Verify the maximum sampling frequency allowed for the number of the 
% selected channels
handles=Verify_sampling_frequency(hObject,handles);
guidata(hObject, handles);

% --- Executes on button press in Channel_8.
function Channel_8_Callback(hObject, eventdata, handles)
% hObject    handle to Channel_8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Channel_8

handles.channel_8=get(handles.Channel_8,'Value');

% Update handles structure
guidata(hObject, handles);

% Verify the maximum sampling frequency allowed for the number of the 
% selected channels
handles=Verify_sampling_frequency(hObject,handles);
guidata(hObject, handles);

% --- Executes on button press in Channel_9.
function Channel_9_Callback(hObject, eventdata, handles)
% hObject    handle to Channel_9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Channel_9

handles.channel_9=get(handles.Channel_9,'Value');

% Update handles structure
guidata(hObject, handles);

% Verify the maximum sampling frequency allowed for the number of the 
% selected channels
handles=Verify_sampling_frequency(hObject,handles);
guidata(hObject, handles);

% --- Executes on button press in Channel_10.
function Channel_10_Callback(hObject, eventdata, handles)
% hObject    handle to Channel_10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Channel_10

handles.channel_10=get(handles.Channel_10,'Value');

% Update handles structure
guidata(hObject, handles);

% Verify the maximum sampling frequency allowed for the number of the 
% selected channels
handles=Verify_sampling_frequency(hObject,handles);
guidata(hObject, handles);

% --- Executes on button press in Channel_11.
function Channel_11_Callback(hObject, eventdata, handles)
% hObject    handle to Channel_11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Channel_11

handles.channel_11=get(handles.Channel_11,'Value');

% Update handles structure
guidata(hObject, handles);

% Verify the maximum sampling frequency allowed for the number of the 
% selected channels
handles=Verify_sampling_frequency(hObject,handles);
guidata(hObject, handles);

% --- Executes on button press in Channel_12.
function Channel_12_Callback(hObject, eventdata, handles)
% hObject    handle to Channel_12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Channel_12

handles.channel_12=get(handles.Channel_12,'Value');

% Update handles structure
guidata(hObject, handles);

% Verify the maximum sampling frequency allowed for the number of the 
% selected channels
handles=Verify_sampling_frequency(hObject,handles);
guidata(hObject, handles);

%*************************************************************************%
%           END Channel_n Callback                                        %
%           ---------------------------                                   %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Save_to_PC Callback                                     %
%           ---------------------------                                   %
%*************************************************************************%

% --- Executes on button press in Save_to_PC.
function Save_to_PC_Callback(hObject, eventdata, handles)
% hObject    handle to Save_to_PC (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Save_to_PC

handles.pc=get(handles.Save_to_PC,'Value');

% Update handles structure
guidata(hObject, handles);

%*************************************************************************%
%           END Save_to_PC Callback                                       %
%           -------------------------                                     %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Save_to_SD Callback                                     %
%           ---------------------------                                   %
%*************************************************************************%

% --- Executes on button press in Save_to_SD.
function Save_to_SD_Callback(hObject, eventdata, handles)
% hObject    handle to Save_to_SD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Save_to_SD

handles.sd=get(handles.Save_to_SD,'Value');

% Update handles structure
guidata(hObject, handles);


%*************************************************************************%
%           END Save_to_SD Callback                                       %
%           -------------------------                                     %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Selected_directory_edit CreateFcn                       %
%           ---------------------------------------                       %
%*************************************************************************%

% --- Executes during object creation, after setting all properties.
function Selected_directory_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Selected_directory_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%*************************************************************************%
%           END Selected_directory_edit CreateFcn                         %
%           -------------------------------------                         %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Selected_directory_edit Callback                        %
%           --------------------------------------                        %
%*************************************************************************%

function Selected_directory_edit_Callback(hObject, eventdata, handles)
% hObject    handle to Selected_directory_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Selected_directory_edit as text
%        str2double(get(hObject,'String')) returns contents of Selected_directory_edit as a double


selected_directory_online=handles.selected_directory_online;

handles.selected_directory_online=get(handles.Selected_directory_edit,'String');

if exist(handles.selected_directory_online)==0
    handles.selected_directory_online=selected_directory_online;
    warndlg('The selected directory does not exist');
end

set(handles.Selected_directory_edit,'String',handles.selected_directory_online);

% Update handles structure
guidata(hObject, handles);


%*************************************************************************%
%           END Selected_directory_edit Callback                          %
%           ------------------------------------                          %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Browse_directory Callback                               %
%           -------------------------------                               %
%*************************************************************************%


% --- Executes on button press in Browse_directory.
function Browse_directory_Callback(hObject, eventdata, handles)
% hObject    handle to Browse_directory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

selected_directory_online=handles.selected_directory_online;

selected_directory_online=uigetdir(selected_directory_online,'Choose the directory');

if selected_directory_online~=0
    if exist(selected_directory_online)~=0
        handles.selected_directory_online=selected_directory_online;
    end
end

set(handles.Selected_directory_edit,'String',handles.selected_directory_online);

% Update handles structure
guidata(hObject, handles);

%*************************************************************************%
%           END Browse_directory Callback                                 %
%           -----------------------------                                 %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Selected_date CreateFcn                                 %
%           ----------------------------------                            %
%*************************************************************************%

% --- Executes during object creation, after setting all properties.
function Selected_date_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Selected_date (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%*************************************************************************%
%           END Selected_date CreateFcn                                   %
%           --------------------------------                              %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Selected_date Callback                                  %
%           ---------------------------------                             %
%*************************************************************************%

function Selected_date_Callback(hObject, eventdata, handles)
% hObject    handle to Selected_date (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Selected_date as text
%        str2double(get(hObject,'String')) returns contents of Selected_date as a double

handles.selected_date=get(handles.Selected_date,'String');

current_name=[handles.selected_site,'_',handles.selected_date];
     
handles.selected_file_name=current_name;

name=[handles.selected_directory_online,filesep,handles.selected_file_name];

if exist(name)~=0
    warndlg('The file name exists. It will be replaced');
end


% Update handles structure
guidata(hObject, handles);

%*************************************************************************%
%           END Selected_date Callback                               %
%           -------------------------------                               %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Selected_site CreateFcn                                 %
%           ----------------------------------                            %
%*************************************************************************%

% --- Executes during object creation, after setting all properties.
function Selected_site_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Selected_site (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%*************************************************************************%
%           END Selected_site CreateFcn                                   %
%           ----------------------------------                            %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Selected_site Callback                                  %
%           ------------------------------                                %
%*************************************************************************%

function Selected_site_Callback(hObject, eventdata, handles)
% hObject    handle to Selected_site (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Selected_site as text
%        str2double(get(hObject,'String')) returns contents of Selected_site as a double

handles.selected_site=get(handles.Selected_site,'String');

current_name=[handles.selected_site,'_',handles.selected_date];
     
handles.selected_file_name=current_name;

name=[handles.selected_directory_online,filesep,handles.selected_file_name];

if exist(name)~=0
    warndlg('The file name exists. It will be replaced');
end

% Update handles structure
guidata(hObject, handles);


%*************************************************************************%
%           END Selected_site Callback                                    %
%           ------------------------------                                %
%*************************************************************************%

%*************************************************************************%
%           BEGIN load_setup Callback                                     %
%           -------------------------                                     %
%*************************************************************************%

% --- Executes on button press in load_setup.
function Load_setup_Callback(hObject, eventdata, handles)
% hObject    handle to load_setup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[name,path]=uigetfile('*.mat','Load the current parameters');
name=[path,name];

if name~=0
    
    cad=['load ',name];
    eval(cad);

    if exist('current_setup')~=0

        % Set the different parameters of the acquisition process
        % Serial ports
        serialInfo = instrhwinfo('serial');
        serial_values2=serialInfo.AvailableSerialPorts;
        serial_values(1,1)={'None'};
   
        serial_values(2:1+length(serial_values2),1)=serial_values2;
        handles.serial_values=serial_values;

        set(handles.Serial_port_edit,'String',serial_values);

        d=(strcmp((serial_values),current_setup.serial_port_name));

        if sum(d)==0
            set(handles.Serial_port_edit,'Value',1);
            serial_port_name=serial_values(1);
            handles.serial_port_name=serial_port_name;
        else
            handles.serial_port_name=current_setup.serial_port_name;
            indx=find(d==1);
            set(handles.Serial_port_edit,'Value',indx);
        end
        
        % Connect with series port (1 -> Open)
        handles=Connect_serial_port(hObject,handles,'1');
        
        % Send USB command to Arduino
        handles=Send_command(hObject,handles,'USB');
        
        % Samplng frequency
        handles.sampling_frequency=current_setup.sampling_frequency;
        indx=find(cell2mat(handles.sampling_frequency_values)==handles.sampling_frequency);
        set(handles.Sampling_frequency_edit,'Value',indx);

        % Voltage gain
        handles.voltage_gain=current_setup.voltage_gain;
        indx=find(cell2mat(handles.voltage_gain_values)==handles.voltage_gain);
        set(handles.Voltage_gain_edit,'Value',indx);

        % Dynamic range
        handles.dynamic_range=current_setup.dynamic_range;
        set(handles.Dynamic_range_edit,'String',num2str(handles.dynamic_range));
        
        % Voltage levels
        handles.voltage_levels=current_setup.voltage_levels;
        set(handles.Voltage_levels_edit,'String',num2str(handles.voltage_levels));

        % Duration
        handles.duration=current_setup.duration;
        set(handles.Duration_edit,'String',num2str(handles.duration));

        % Channels
        handles.channel_1=current_setup.channel_1;
        handles.channel_2=current_setup.channel_2;
        handles.channel_3=current_setup.channel_3;
        handles.channel_4=current_setup.channel_4;
        handles.channel_5=current_setup.channel_5;
        handles.channel_6=current_setup.channel_6;
        handles.channel_7=current_setup.channel_7;
        handles.channel_8=current_setup.channel_8;
        handles.channel_9=current_setup.channel_9;
        handles.channel_10=current_setup.channel_10;
        handles.channel_11=current_setup.channel_11;
        handles.channel_12=current_setup.channel_12;
        
        set(handles.Channel_1,'Value',handles.channel_1);
        set(handles.Channel_2,'Value',handles.channel_2);
        set(handles.Channel_3,'Value',handles.channel_3);
        set(handles.Channel_4,'Value',handles.channel_4);
        set(handles.Channel_5,'Value',handles.channel_5);
        set(handles.Channel_6,'Value',handles.channel_6);
        set(handles.Channel_7,'Value',handles.channel_7);
        set(handles.Channel_8,'Value',handles.channel_8);
        set(handles.Channel_9,'Value',handles.channel_9);
        set(handles.Channel_10,'Value',handles.channel_10);
        set(handles.Channel_11,'Value',handles.channel_11);
        set(handles.Channel_12,'Value',handles.channel_12);
        
        % Save to PC / SD
        handles.pc=current_setup.pc;
        handles.sd=current_setup.sd;
        
        set(handles.Save_to_PC,'Value',handles.pc);
        set(handles.Save_to_SD,'Value',handles.sd);
     
        % Selected directory 
        selected_directory_online=handles.selected_directory_online;
        handles.selected_directory_online=current_setup.selected_directory_online;
        
        if exist(handles.selected_directory_online)==0
            handles.selected_directory_online=selected_directory_online;
        end
        
        set(handles.Selected_directory_edit,'String',handles.selected_directory_online);
        
        % Selected site
        handles.selected_site=current_setup.selected_site;
        set(handles.Selected_site,'String',handles.selected_site);
        
    else
         warndlg('The variable current_setup is not found in this file');
    end

    % Update handles structure
    guidata(hObject, handles);

end

%*************************************************************************%
%           END load_setup Callback                                       %
%           -----------------------                                       %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Save_setup Callback                                     %
%           -------------------------                                     %
%*************************************************************************%

% --- Executes on button press in save_setup.
function Save_setup_Callback(hObject, eventdata, handles)
% hObject    handle to save_setup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Acquisition parameters
current_setup.serial_port_name=handles.serial_port_name;
current_setup.sampling_frequency=handles.sampling_frequency;
current_setup.voltage_gain=handles.voltage_gain;
current_setup.dynamic_range=handles.dynamic_range;
current_setup.voltage_levels=handles.voltage_levels;
current_setup.duration=handles.duration;

% Channels
current_setup.channel_1=handles.channel_1;
current_setup.channel_2=handles.channel_2;
current_setup.channel_3=handles.channel_3;
current_setup.channel_4=handles.channel_4;
current_setup.channel_5=handles.channel_5;
current_setup.channel_6=handles.channel_6;
current_setup.channel_7=handles.channel_7;
current_setup.channel_8=handles.channel_8;
current_setup.channel_9=handles.channel_9;
current_setup.channel_10=handles.channel_10;
current_setup.channel_11=handles.channel_11;
current_setup.channel_12=handles.channel_12;

% Save to PC / SD
current_setup.pc=handles.pc;
current_setup.sd=handles.sd;

% Selected directory
current_setup.selected_directory_online=handles.selected_directory_online;

% Selected site
current_setup.selected_site=handles.selected_site;
        
% Save file with the selected name
[name,path]=uiputfile('*.mat','Save the current parameters');
name=[path,name];

% Save the default file ( current_setup.mat )
cad=['save ',name,' current_setup;'];
eval(cad);

save current_setup.mat current_setup;

%*************************************************************************%
%           END Save_setup Callback                                       %
%           -------------------------                                     %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Send_setup Callback                                     %
%           -------------------------                                     %
%*************************************************************************%

% --- Executes on button press in send_setup.
function Send_setup_Callback(hObject, eventdata, handles)
% hObject    handle to send_setup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get the configuration data and prepare the string to Arduino

% Sampling frequency
sampling_frequency=handles.sampling_frequency;
w=[num2str(sampling_frequency),' '];

% Voltage gain
gain=handles.voltage_gain;
w=[w,num2str(gain),' '];  

% Dynamic range
dynamic_range=handles.dynamic_range;
% Voltage levels
voltage_levels=handles.voltage_levels;
% Voltage conversion (V/levels)
n = dynamic_range / voltage_levels;
w=[w,num2str(n),' '];

% Recording duration (in samples)
number_samples=sampling_frequency*60*handles.duration;
w=[w,num2str(number_samples),' '];

% Window length (in samples)
handles.time_window_length=1;
paso=handles.time_window_length*sampling_frequency;

% Window lenght plot
handles.time_window_length_plot=10;
paso_plot=(handles.time_window_length_plot)*sampling_frequency;
paso_plot_m1=(handles.time_window_length_plot-1)*sampling_frequency;

% Selected channels

channel(1)=handles.channel_1;
w=[w,num2str(channel(1)),' '];
channel(2)=handles.channel_2;
w=[w,num2str(channel(2)),' '];
channel(3)=handles.channel_3;
w=[w,num2str(channel(3)),' '];
channel(4)=handles.channel_4;
w=[w,num2str(channel(4)),' '];
channel(5)=handles.channel_5;
w=[w,num2str(channel(5)),' '];
channel(6)=handles.channel_6;
w=[w,num2str(channel(6)),' '];
channel(7)=handles.channel_7;
w=[w,num2str(channel(7)),' '];
channel(8)=handles.channel_8;
w=[w,num2str(channel(8)),' '];
channel(9)=handles.channel_9;
w=[w,num2str(channel(9)),' '];
channel(10)=handles.channel_10;
w=[w,num2str(channel(10)),' '];
channel(11)=handles.channel_11;
w=[w,num2str(channel(11)),' '];
channel(12)=handles.channel_12;
w=[w,num2str(channel(12)),' '];

num_channel=1+find(channel==1);

% Save file to PC and/or SD
pc_file=handles.pc;
sd_file=handles.sd;
w=[w,num2str(sd_file),' '];

% Send only configuration
w=[w,'0'];

% Selected directory
current_folder=handles.selected_directory_online;

current_site=handles.selected_site;

% Refresh file name with the current date/hour

current_date=regexprep(datestr(now),'-','');
current_date=regexprep(current_date,':','');
current_date=regexprep(current_date,' ','_');
current_name=[current_site,'_',current_date];

handles.selected_date=current_date;

handles.selected_file_name=current_name;
set(handles.Selected_date,'String',handles.selected_date);

% Selected file name
current_name=handles.selected_file_name;
complete_name=[current_folder,filesep,current_name];

w=[w,current_name,';'];

% Send configuration to Arduino
handles=Send_command(hObject,handles,w);

% Recieve the same data (first value)
c = fgetl(handles.serial_port);
    
% Update handles structure
guidata(hObject, handles);

%*************************************************************************%
%           END Send_setup Callback                                       %
%           ------------------------                                      %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Send_start Callback                                     %
%           -------------------------                                     %
%*************************************************************************%

% --- Executes on button press in Send_start.
function Send_start_Callback(hObject, eventdata, handles)
% hObject    handle to Send_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global stop_acquisition;
stop_acquisition=0;

% Hide the initial text
set(handles.Text_image_row1,'Visible','off');
set(handles.Text_image_row2,'Visible','off');

% Disable all the options (excepting 'Stop acquistion)
handles=Enable_options(hObject,handles,'off');
set(handles.Send_stop,'Enable','on');
   
% Get the configuration data and prepare the string to Arduino

% Sampling frequency
sampling_frequency=handles.sampling_frequency;
w=[num2str(sampling_frequency),' '];

% Voltage gain
gain=handles.voltage_gain;
w=[w,num2str(gain),' '];  

% Dynamic range
dynamic_range=handles.dynamic_range;
% Voltage levels
voltage_levels=handles.voltage_levels;
% Voltage conversion (V/levels)
n = dynamic_range / voltage_levels;
w=[w,num2str(n),' '];

% Recording duration (in samples)
number_samples=sampling_frequency*60*handles.duration;
w=[w,num2str(number_samples),' '];

% Window length (in samples)
handles.time_window_length=1;
paso=handles.time_window_length*sampling_frequency;

% Window lenght plot
handles.time_window_length_plot=10;
paso_plot=(handles.time_window_length_plot)*sampling_frequency;
paso_plot_m1=(handles.time_window_length_plot-1)*sampling_frequency;

% Selected channels

channel(1)=handles.channel_1;
w=[w,num2str(channel(1)),' '];
channel(2)=handles.channel_2;
w=[w,num2str(channel(2)),' '];
channel(3)=handles.channel_3;
w=[w,num2str(channel(3)),' '];
channel(4)=handles.channel_4;
w=[w,num2str(channel(4)),' '];
channel(5)=handles.channel_5;
w=[w,num2str(channel(5)),' '];
channel(6)=handles.channel_6;
w=[w,num2str(channel(6)),' '];
channel(7)=handles.channel_7;
w=[w,num2str(channel(7)),' '];
channel(8)=handles.channel_8;
w=[w,num2str(channel(8)),' '];
channel(9)=handles.channel_9;
w=[w,num2str(channel(9)),' '];
channel(10)=handles.channel_10;
w=[w,num2str(channel(10)),' '];
channel(11)=handles.channel_11;
w=[w,num2str(channel(11)),' '];
channel(12)=handles.channel_12;
w=[w,num2str(channel(12)),' '];

num_channel=1+find(channel==1);

% Save file to PC and/or SD
pc_file=handles.pc;
sd_file=handles.sd;
w=[w,num2str(sd_file),' '];

% Send configuration and start acquisition
w=[w,'1'];

% Selected directory
current_folder=handles.selected_directory_online;

% Selected site
current_site=handles.selected_site;

% Refresh file name with the current date/hour
    
current_date=regexprep(datestr(now),'-','');
current_date=regexprep(current_date,':','');
current_date=regexprep(current_date,' ','_');
current_name=[current_site,'_',current_date];

handles.selected_date=current_date;

handles.selected_file_name=current_name;
set(handles.Selected_date,'String',handles.selected_date);
    
% Selected file name
current_name=handles.selected_file_name;
complete_name=[current_folder,filesep,current_name];

w=[w,current_name,';'];

% BEGIN Save in saf format
if pc_file==1
    
    cad1='SESAME ASCII data format (saf) v. 1   (this line must not  be modified) \n';
    cad2=['SAMP_FREQ =  ',num2str(sampling_frequency),'\n'];
    cad3=['NDAT = ',num2str(number_samples),'\n'];
    cad4=['VOLTAGE GAIN = ',num2str(n),'\n'];

    date_name=regexprep(datestr(now),'-','');
    date_name=regexprep(date_name,':','');
    date_name=regexprep(date_name,' ','_');

    cad5=['START_TIME = ',date_name,'\n'];
    cad6='UNITS = volts \n';
    cad7=['Recording channels : ',num2str(find(channel==1)),'\n'];
    cad7a='CH0_ID = S Z \n';
    cad7b='CH1_ID = S N \n';
    cad7c='CH2_ID = S E \n';
    cad8='####------------------------------------------- \n';


    if strcmp(complete_name(length(complete_name)-2:length(complete_name)),'mat')==1
        complete_name2=[complete_name(1:length(complete_name)-3),'.saf'];
    else
        complete_name2=[complete_name,'.saf'];
    end

    file=fopen(complete_name2,'a+');

    fprintf(file,cad1);
    fprintf(file,cad2);
    fprintf(file,cad3);
    fprintf(file,cad4);
    fprintf(file,cad5);
    fprintf(file,cad6);
    fprintf(file,cad7);
    fprintf(file,cad7a);
    fprintf(file,cad7b);
    fprintf(file,cad7c);
    fprintf(file,cad8);

end

% Send configuration to Arduino
handles=Send_command(hObject,handles,w);

% Disable warning
warning off;
lastwarn('');

% Recieve the same data (first value)
c = fgetl(handles.serial_port);
        
% Test any Timeout warning
msgstr = lastwarn;
if isempty(strfind(msgstr,'timeout'))

    % Acquisition of samples
    count=1;
    figu_count=0;

    axis(handles.axes1);
    aa34=plot(1,1);
    xlabel('Time (s)')
    ylabel('# channel')
    refreshdata(handles.axes1,'caller');
    drawnow;
    
    % Show RMS text 
    set(handles.RMS_text,'String','RMS values');
    set(handles.RMS_text,'FontWeight','Bold');
      
    set(handles.V_1,'String','V');
    set(handles.V_2,'String','V');
    set(handles.V_3,'String','V');
    set(handles.V_4,'String','V');
    set(handles.V_5,'String','V');
    set(handles.V_6,'String','V');
    set(handles.V_7,'String','V');
    set(handles.V_8,'String','V');
    set(handles.V_9,'String','V');
    set(handles.V_10,'String','V');
    set(handles.V_11,'String','V');
    set(handles.V_12,'String','V');
    
    
    while count < number_samples + 1   

        % Set to zero the data matrix
        y(1:13)=0;

        % Receive a new line from the serial port
        c = fgetl(handles.serial_port);
        
        if isempty(c)==1
            break;
        end
        
        if length(strfind(c,';'))==length(num_channel)
            c_copia=c;
        else
            c=c_copia;
        end
        
        if pc_file==1
            %fprintf(file,'%s \n',c);
            fprintf(file,'%s',c);
        end
        
        % Split the values
        c= strsplit(c,';');
                    
        % Convert to numeric array
        c = cellfun(@str2num,c);
        % Save the time values
        y(1)=c(1);
        % Convert to voltage
        v=c(1,2:end)*n; 

        i2=1;
        for i=num_channel % 12 channels maximum
            % Copy the amplitude values
            y(i)=channel(i-1)*v(i2); 
            i2=i2+1;
        end

        % Matrix with time and amplitude values
        X (count, : ) = y; 
                  
        % Plot the recording data
        m(1:paso_plot,1:13)=0;
        m_media(1:paso_plot,1:13)=0;

        if rem(count,paso)==0 && count<(paso_plot)
            
           % Data channels
           m(paso_plot-count+1:paso_plot,2)=X(1:count,2);
           m(paso_plot-count+1:paso_plot,3)=X(1:count,3);
           m(paso_plot-count+1:paso_plot,4)=X(1:count,4);
           m(paso_plot-count+1:paso_plot,5)=X(1:count,5);
           m(paso_plot-count+1:paso_plot,6)=X(1:count,6);
           m(paso_plot-count+1:paso_plot,7)=X(1:count,7);
           m(paso_plot-count+1:paso_plot,8)=X(1:count,8);
           m(paso_plot-count+1:paso_plot,9)=X(1:count,9);
           m(paso_plot-count+1:paso_plot,10)=X(1:count,10);
           m(paso_plot-count+1:paso_plot,11)=X(1:count,11);
           m(paso_plot-count+1:paso_plot,12)=X(1:count,12);
           m(paso_plot-count+1:paso_plot,13)=X(1:count,13);

        
           % Normalize the data amplitudes to 0.5
           
           for gi=2:13
               m_media(paso_plot-count+1:paso_plot,gi)=gi-1;
           end
                              
           for gi=num_channel
               m_media(paso_plot-count+1:paso_plot,gi)=m(paso_plot-count+1:paso_plot,gi)-mean(m(paso_plot-count+1:paso_plot,gi));
               max_ampl(gi)=max(abs(m_media(:,gi)));

           end
 
           for gi=num_channel
                m_media(:,gi)=(gi-1)+m_media(:,gi)/(2*max_ampl(gi));
           end

           % Define time vector
           min_time=-paso_plot+count;
           max_time=count-1;
           vector_time=(min_time:max_time)/sampling_frequency;
                                  
           % Plot the current data window
           axis(handles.axes1);
           plot(vector_time,m_media(:,2:13));

           xlabel('Time (s)')
           ylabel('# channel')
        
           axis([round(vector_time(1)) round(vector_time(end)) 0 12.98]);
           
           nn=round(vector_time(1)):(round(vector_time(end))-round(vector_time(1)))/10:round(vector_time(end));
           set(handles.axes1,'XTick',nn);
           
           refreshdata(handles.axes1,'caller');
           drawnow;
           
            % Show RMS values
           set(handles.rms_1,'String',num2str(rms(m(paso_plot-count+1:paso_plot,2))));
           set(handles.rms_2,'String',num2str(rms(m(paso_plot-count+1:paso_plot,3))));
           set(handles.rms_3,'String',num2str(rms(m(paso_plot-count+1:paso_plot,4))));
           set(handles.rms_4,'String',num2str(rms(m(paso_plot-count+1:paso_plot,5))));
           set(handles.rms_5,'String',num2str(rms(m(paso_plot-count+1:paso_plot,6))));
           set(handles.rms_6,'String',num2str(rms(m(paso_plot-count+1:paso_plot,7))));
           set(handles.rms_7,'String',num2str(rms(m(paso_plot-count+1:paso_plot,8))));
           set(handles.rms_8,'String',num2str(rms(m(paso_plot-count+1:paso_plot,9))));
           set(handles.rms_9,'String',num2str(rms(m(paso_plot-count+1:paso_plot,10))));
           set(handles.rms_10,'String',num2str(rms(m(paso_plot-count+1:paso_plot,11))));
           set(handles.rms_11,'String',num2str(rms(m(paso_plot-count+1:paso_plot,12))));
           set(handles.rms_12,'String',num2str(rms(m(paso_plot-count+1:paso_plot,13))));

        end

        if rem(count,paso)==0 && count>=(paso_plot)
                              
           % Define time vector
           min_time=-paso_plot+count;
           max_time=count-1;
           vector_time=(min_time:max_time)/sampling_frequency;
                      
           % Data channels
           m(1:paso_plot,2)=X(figu_count*paso+1:(paso_plot_m1)+(figu_count+1)*paso,2);
           m(1:paso_plot,3)=X(figu_count*paso+1:(paso_plot_m1)+(figu_count+1)*paso,3);
           m(1:paso_plot,4)=X(figu_count*paso+1:(paso_plot_m1)+(figu_count+1)*paso,4);
           m(1:paso_plot,5)=X(figu_count*paso+1:(paso_plot_m1)+(figu_count+1)*paso,5);
           m(1:paso_plot,6)=X(figu_count*paso+1:(paso_plot_m1)+(figu_count+1)*paso,6);
           m(1:paso_plot,7)=X(figu_count*paso+1:(paso_plot_m1)+(figu_count+1)*paso,7);
           m(1:paso_plot,8)=X(figu_count*paso+1:(paso_plot_m1)+(figu_count+1)*paso,8);
           m(1:paso_plot,9)=X(figu_count*paso+1:(paso_plot_m1)+(figu_count+1)*paso,9);
           m(1:paso_plot,10)=X(figu_count*paso+1:(paso_plot_m1)+(figu_count+1)*paso,10);
           m(1:paso_plot,11)=X(figu_count*paso+1:(paso_plot_m1)+(figu_count+1)*paso,11);
           m(1:paso_plot,12)=X(figu_count*paso+1:(paso_plot_m1)+(figu_count+1)*paso,12);
           m(1:paso_plot,13)=X(figu_count*paso+1:(paso_plot_m1)+(figu_count+1)*paso,13);

           % Normalize the data amplitudes to 0.5
            
           for gi=2:13
               m_media(1:paso_plot,gi)=gi-1;
           end
           
           for gi=num_channel
               m_media(1:paso_plot,gi)=m(1:paso_plot,gi)-mean(m(1:paso_plot,gi));
               max_ampl(gi)=max(abs(m_media(1:paso_plot,gi)));

           end
 
           for gi=num_channel
                m_media(1:paso_plot,gi)=(gi-1)+m_media(1:paso_plot,gi)/(2*max_ampl(gi));
           end
                       
           % Plot the current data window
           axis(handles.axes1);
           plot(vector_time,m_media(1:paso_plot,2:13));
           
           xlabel('Time (s)')
           ylabel('# channel')
                     
           axis([round(vector_time(1)) round(vector_time(end)) 0 12.98]);
           
           nn=round(vector_time(1)):(round(vector_time(end))-round(vector_time(1)))/10:round(vector_time(end));
           set(handles.axes1,'XTick',nn);
                   
           refreshdata(handles.axes1,'caller');
           drawnow;
           
           % Show RMS values
           set(handles.rms_1,'String',num2str(rms(m(1:paso_plot,2))));
           set(handles.rms_2,'String',num2str(rms(m(1:paso_plot,3))));
           set(handles.rms_3,'String',num2str(rms(m(1:paso_plot,4))));
           set(handles.rms_4,'String',num2str(rms(m(1:paso_plot,5))));
           set(handles.rms_5,'String',num2str(rms(m(1:paso_plot,6))));
           set(handles.rms_6,'String',num2str(rms(m(1:paso_plot,7))));
           set(handles.rms_7,'String',num2str(rms(m(1:paso_plot,8))));
           set(handles.rms_8,'String',num2str(rms(m(1:paso_plot,9))));
           set(handles.rms_9,'String',num2str(rms(m(1:paso_plot,10))));
           set(handles.rms_10,'String',num2str(rms(m(1:paso_plot,11))));
           set(handles.rms_11,'String',num2str(rms(m(1:paso_plot,12))));
           set(handles.rms_12,'String',num2str(rms(m(1:paso_plot,13))));

           figu_count=figu_count+1;
        end

        count = count +1;
                           
        if stop_acquisition==1
            disp('Stop acquisition');
            handles=Send_command(hObject,handles,'1');
         
        end    

    end
  
    % Normalize the data amplitudes to 0.5
    
       
    for gi=2:13
        m_media(1:length(X),gi)=gi-1;
    end

    for gi=num_channel
        m_media(:,gi)=X(:,gi)-mean(X(:,gi));
        max_ampl(gi)=max(abs(m_media(:,gi)));
    end

    for gi=num_channel
         m_media(:,gi)=(gi-1)+m_media(:,gi)/(2*max_ampl(gi));
    end

    % Plot the complete register
    axis(handles.axes1);
    vector_time=(1:length(X))/sampling_frequency;
    plot(vector_time,m_media(:,2:13));

    xlabel('Time (s)')
    ylabel('# channel')

    ax1=axis;
    axis([ax1(1) ax1(2) 0 12.98]);
    
    nn=round(vector_time(1)):(round(vector_time(end))-round(vector_time(1)))/10:round(vector_time(end));
    set(handles.axes1,'XTick',nn);

    refreshdata(handles.axes1,'caller');
    drawnow;

    % Show RMS values
    set(handles.rms_1,'String',num2str(rms(X(:,2))));
    set(handles.rms_2,'String',num2str(rms(X(:,3))));
    set(handles.rms_3,'String',num2str(rms(X(:,4))));
    set(handles.rms_4,'String',num2str(rms(X(:,5))));
    set(handles.rms_5,'String',num2str(rms(X(:,6))));
    set(handles.rms_6,'String',num2str(rms(X(:,7))));
    set(handles.rms_7,'String',num2str(rms(X(:,8))));
    set(handles.rms_8,'String',num2str(rms(X(:,9))));
    set(handles.rms_9,'String',num2str(rms(X(:,10))));
    set(handles.rms_10,'String',num2str(rms(X(:,11))));
    set(handles.rms_11,'String',num2str(rms(X(:,12))));
    set(handles.rms_12,'String',num2str(rms(X(:,13))));
    
    
    % Close the saf file
    if pc_file==1

        fclose (file);
        save X.mat X;

    end
    
    
    if stop_acquisition==1
        
         c = fgetl(handles.serial_port);
         
        while isempty(c)==0
         c = fgetl(handles.serial_port);
        end
    end    
        
    % Stop buzzer
    disp('Stop buzzer');
    handles=Send_command(hObject,handles,'1');

    % Ready for new acquisition
    handles=Send_command(hObject,handles,'USB');
     
else
    warndlg('A timeout occured before acquiring the data');

    % Connect with series port (0 -> Closed)
    handles=Connect_serial_port(hObject,handles,'0');

end

% Enable all the options 
handles=Enable_options(hObject,handles,'on');

%*************************************************************************%
%           END Send_start Callback                                       %
%           ------------------------                                      %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Send_stop Callback                                      %
%           ------------------------                                      %
%*************************************************************************%

% --- Executes on button press in Send_stop.
function Send_stop_Callback(hObject, eventdata, handles)
% hObject    handle to Send_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global stop_acquisition;
stop_acquisition=1;

% Update handles structure
guidata(hObject, handles);

%*************************************************************************%
%           END Send_stop Callback                                        %
%           ------------------------                                      %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Send_command                                            %
%           ------------------                                            %
%*************************************************************************%

function handles=Send_command(hObject,handles,command_w)

if strcmp(cell2mat(handles.serial_port_name),'None')==0
        
    % Test if the serial port is currently open
    if strcmp(handles.serial_port.Status,'closed')==0
        
        fprintf(handles.serial_port,command_w);
        
    end
end

% Update handles structure
guidata(hObject, handles);

%*************************************************************************%
%           END Send_command                                              %
%           ----------------                                              %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Connect_serial_port                                     %
%           --------------------------                                    %
%*************************************************************************%

function handles=Connect_serial_port(hObject,handles,command)


if strcmp(cell2mat(handles.serial_port_name),'None')==0
    
    if command=='1' % Open the serial port
    
        % Enable Send setup, Start and Stop buttons
        set(handles.Send_setup,'Enable','on');
        set(handles.Send_start,'Enable','on');
        set(handles.Send_stop,'Enable','on');
        
        % Setup the serial port
        delete (instrfind ({'Port'},{cell2mat(handles.serial_port_name)}));
        serial_port = serial (cell2mat(handles.serial_port_name));
        handles.serial_port=serial_port;

        serial_port.BaudRate = 115200;
        serial_port.InputBufferSize = 2048; 

        % Test if the serial port is currently open
        if strcmp(serial_port.Status,'closed')==0

            fclose(serial_port);
        end

        % Open the serial port
        error=0;
        
        try 
            fopen (serial_port);
            pause(1);

        catch

            serial_port_name=handles.serial_values(1);
            handles.serial_port_name=serial_port_name;
            set(handles.Serial_port_edit,'Value',1);
            
            error=1;

            % Disable Send setup, Start and Stop buttons
            set(handles.Send_setup,'Enable','off');
            set(handles.Send_start,'Enable','off');
            set(handles.Send_stop,'Enable','off');

            warndlg('Serial port connection has not been established');
        end
        
        if error==0
            
            % Enable all the options
            handles=Enable_options(hObject,handles,'on');
                        
        end
    
    else
       fclose(handles.serial_port);
       
       % Disable Send setup, Start and Stop buttons
       set(handles.Send_setup,'Enable','off');
       set(handles.Send_start,'Enable','off');
       set(handles.Send_stop,'Enable','off');
       
    end

else
    % Disable Send setup, Start and Stop buttons
    set(handles.Send_setup,'Enable','off');
    set(handles.Send_start,'Enable','off');
    set(handles.Send_stop,'Enable','off');
        
end

% Update handles structure
guidata(hObject, handles);

%*************************************************************************%
%           END Connect_serial_port                                       %
%           -------------------------                                     %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Verify_sampling_frequency                               %
%           -------------------------------                               %
%*************************************************************************%

function handles=Verify_sampling_frequency(hObject,handles)

% Verify the number of selected channels
count_channels=0;
count_channels=count_channels+get(handles.Channel_1,'Value');
count_channels=count_channels+get(handles.Channel_2,'Value');
count_channels=count_channels+get(handles.Channel_3,'Value');
count_channels=count_channels+get(handles.Channel_4,'Value');
count_channels=count_channels+get(handles.Channel_5,'Value');
count_channels=count_channels+get(handles.Channel_6,'Value');
count_channels=count_channels+get(handles.Channel_7,'Value');
count_channels=count_channels+get(handles.Channel_8,'Value');
count_channels=count_channels+get(handles.Channel_9,'Value');
count_channels=count_channels+get(handles.Channel_10,'Value');
count_channels=count_channels+get(handles.Channel_11,'Value');
count_channels=count_channels+get(handles.Channel_12,'Value');

% Modify the sampling frequency values
fre=get(handles.Sampling_frequency_edit,'Value');

if count_channels<=5
    sam={100,125,200,250};
end

if count_channels==6
    sam={100,125,200};
    if fre>3
        fre=3;
        warndlg('The maximum sampling frequency for the selected channels is 200Hz');
    end
end

if count_channels>6 && count_channels<=10
    sam={100,125};
    if fre>2
        fre=2;
        warndlg('The maximum sampling frequency for the selected channels is 125Hz');
    end
end

if count_channels>10 && count_channels<=12
    sam={100};
    if fre>1
        fre=1;
        warndlg('The maximum sampling frequency for the selected channels is 100Hz');
    end
    
end

handles.sampling_frequency_values=sam; 
handles.sampling_frequency=cell2mat(handles.sampling_frequency_values(fre));
set(handles.Sampling_frequency_edit,'String',sam);
set(handles.Sampling_frequency_edit,'Value',fre);

% Update handles structure
guidata(hObject, handles);

%*************************************************************************%
%           END Verify_sampling_frequency                                 %
%           -------------------------------                               %
%*************************************************************************%

%*************************************************************************%
%           BEGIN Enable_options                                          %
%           --------------------                                          %
%*************************************************************************%

function handles=Enable_options(hObject,handles,option)

% Sampling frequency
set(handles.Sampling_frequency_edit,'Enable',option);

% Voltage gain
set(handles.Voltage_gain_edit,'Enable',option);

% Voltage conversion
% Default values for Arduino DUE
set(handles.Dynamic_range_edit,'Enable',option);
set(handles.Voltage_levels_edit,'Enable',option);

% Duration
set(handles.Duration_edit,'Enable',option);

% Channels
set(handles.Channel_1,'Enable',option);
set(handles.Channel_2,'Enable',option);
set(handles.Channel_3,'Enable',option);
set(handles.Channel_4,'Enable',option);
set(handles.Channel_5,'Enable',option);
set(handles.Channel_6,'Enable',option);
set(handles.Channel_7,'Enable',option);
set(handles.Channel_8,'Enable',option);
set(handles.Channel_9,'Enable',option);
set(handles.Channel_10,'Enable',option);
set(handles.Channel_11,'Enable',option);
set(handles.Channel_12,'Enable',option);

% Save file in PC
set(handles.Save_to_PC,'Enable',option);

% Save file in SD
set(handles.Save_to_SD,'Enable',option);

% Selected directory
set(handles.Selected_directory_edit,'Enable',option);

% Selected file name
set(handles.Selected_site,'Enable',option);
set(handles.Selected_date,'Enable','off');

% Buttons
set(handles.Load_setup,'Enable',option);
set(handles.Save_setup,'Enable',option);
set(handles.Send_setup,'Enable',option);
set(handles.Send_start,'Enable',option);
set(handles.Send_stop,'Enable',option);

% Update handles structure
guidata(hObject, handles);


%*************************************************************************%
%           END Enable_options                                            %
%           --------------------                                          %
%*************************************************************************%
