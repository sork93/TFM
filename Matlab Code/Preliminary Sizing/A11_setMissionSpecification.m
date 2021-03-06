%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%                   MISSION ESPECIFICATIONS (ME)                          %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% CLEAR CMD WINDOW & WORKSPACE
clearvars
close all
clc

%% MISSION TYPE:
%Choose one:
% ME.MissionType = 5 ; % Business Jets
ME.MissionType = 11; % Flying boats, amphibious, float airplanes


%% IMPORT CONSTANTS
CST = importConstants();
CST.fuelDensity = 0.82; %kg/l

%% DEFINE FIGURES FOLDER AND POSITION
switch ME.MissionType
    case 5
        ME.FiguresFolder = '5_Figures';
    case 11
        ME.FiguresFolder = '11_Figures';
end      



%% DEFINE CONVERSION FACTORS
%length
    CF.nm2m     = 1852;
    CF.m2ft     = 3.28084;
    CF.ft2m     = 0.3048;
    CF.sm2m     = 1609.3; %Static miles to m
    CF.in2m     = 0.0254;
%speed
    CF.mph2ms   = 0.44704;
    CF.kts2ms   = 0.514444;
    CF.ms2kts   = 1.94384;
    CF.fps2kts  = 0.592484;
%mass
    CF.kg2lbm   = convmass(1,'kg','lbm');
    CF.lbm2kg   = convmass(1,'lbm','kg');
    CF.slug2kg  = 14.593903;
%force
    CF.lbf2N    = 4.448222;
    CF.N2lbf    = 0.224809;
%time
    CF.hour2sec = 3600;
    CF.min2sec  = 60;
%Pressure
    CF.psf2Pa   = CF.lbf2N/CF.ft2m^2;
%Power
    CF.hp2watts = 745.7;
%Other
    CF.TSFC2SI  = CF.lbm2kg/(CF.lbf2N*CF.hour2sec);
    CF.c_p2SI   = CF.lbm2kg*(1/CF.hp2watts)*(1/3600)*CST.GravitySI;

%% LOAD CUSTOM DESING PARAMETERS
run DesignParameters.m

%% PAYLOAD
switch ME.MissionType
    case  5 % business jet
        ME.Passengers = 6;
%         ME.CabinWeight = 1000; %Other weight to be added in kg
%         %Mission payload weight in kg:
%         ME.Payload =  ME.Passengers*(CST.PassengerWeightSI+CST.PassBaggWeightSI)+ME.CabinWeight;
        ME.Payload = DP.Payload; %kg --> Se saca en el excel, mejorar el dato cuando tenga todos los semejantes
        
    case 11 % amphibious
        ME.Payload = 3000;
        ME.Passengers = 10;    
        ME.Cargo.Weigth = ME.Payload - ME.Passengers*(CST.PassengerWeightSI);
        ME.Cargo.Volume = (ME.Cargo.Weigth/160 + ME.Passengers*CST.PassBaggWeightSI/200)  / 0.85 ; % page 79 torenbeek: Density 160 kg m^3, 200 and 0.85 efficiency
        
end


%% CREW
switch ME.MissionType
    case  5 % business jet
        ME.Crew = 2; %Check FAR 91.215 for minimun crew members
        %Mission crew weight in kg:
        ME.CrewWeight = ME.Crew*(CST.CrewWeightSI+CST.CrewBaggWeightSI);
        
    case 11 % amphibious
        ME.Crew = 2; %Check FAR 91.215 for minimun crew members
        %Mission crew weight in kg:
        ME.CrewWeight = ME.Crew*(CST.CrewWeightSI+CST.CrewBaggWeightSI);
end


%% TAKE-OFF
switch ME.MissionType
    case  5 % business jet
        ME.TakeOff.Altitude = 0;     % Take off altitude in m
        ME.TakeOff.S_TOFL = DP.TOFL; % Take off distance in m
        
    case 11 % amphibious
        ME.TakeOff.Altitude = 0;  % Take off altitude in m
        ME.TakeOff.S_TOFL = 700;  % Take off distance in m
end


%% CLIMB
switch ME.MissionType
    case  5 % business jet
        ME.Climb.E_cl    = NaN;           %Time to climb in seconds --> se sobrescribe luego
        ME.Climb.Rate_cl = DP.ClimbRate;  %Rate of climb speed in m/s (vertical) (2500 ft/min)
        ME.Climb.V_cl    = DP.ClimbSpeed; %Climb speed in m/s (horizontal) (270 kts)
        
    case 11 % amphibious
        ME.Climb.E_cl    = NaN;  %Time to climb in seconds
        ME.Climb.Rate_cl = NaN;  %Rate of climb speed in m/s (vertical)
        ME.Climb.V_cl    = NaN;  %Climb speed in m/s (horizontal)
end


%% CRUISE
switch ME.MissionType
    case  5 % business jet
        ME.Cruise.Range    = DP.Range;          % in m
        ME.Cruise.Altitude = DP.CruiseAltitude; % in m
        ME.Cruise.Speed    = DP.CruiseSpeed;    % m/s
        
    case 11 % amphibious
        ME.Cruise.Range = 3500*1e3;     % in m
        ME.Cruise.Altitude = 3048;     % in m
        ME.Cruise.Speed =138.8889;     % m/s
        [~, a, ~, rho] = atmosisa(ME.Cruise.Altitude);
        ME.Cruise.Mach = ME.Cruise.Speed/a;
        ME.Cruise.beta = sqrt(1-ME.Cruise.Mach^2);
        ME.Cruise.Density = rho;
        ME.Cruise.q = 0.5*ME.Cruise.Density*ME.Cruise.Speed^2;
        
        clear a rho
end



%% LOITER
switch ME.MissionType
    case  5 % business jet
        ME.Loiter.E_ltr = DP.LoiterTime;    %Loiter time in seconds
        ME.Loiter.V_ltr = ME.Cruise.Speed;  %Loiter speed in m/s
        
    case 11 % amphibious
        ME.Loiter.E_ltr = 30*CF.min2sec;    %Loiter time in seconds
        ME.Loiter.V_ltr = ME.Cruise.Speed;  %Loiter speed in m/s
end


%% ALTERNATE
switch ME.MissionType
    case 5 % business jet
        ME.Alternate.R_alt = DP.AlternateRange; %Range to alternate airport (200 nautic miles --> 370km)
        ME.Alternate.V_alt = 250*CF.kts2ms;     %If flight is below 10.000ft (typical) max speed is 250kts because of FAA regulations
        
    case 11 % amphibious
        ME.Alternate.R_alt = 370*1e3;       %Range to alternate airport (200 nautic miles --> 370km)
        ME.Alternate.V_alt = 250*CF.kts2ms; %If flight is below 10.000ft (typical) max speed is 250kts because of FAA regulations
        
end


%% LANDING
switch ME.MissionType
    case 5
        ME.Landing.S_LFL = DP.LFL; %Length of the landing field [m]
    case 11
        ME.Landing.S_LFL = 1000; %Length of the landing field [m]
        ME.Landing.Altitude = 0;
end


%% POWERPLANT
%Choose one: 'propeller', 'jet'

switch ME.MissionType
    case  5 % business jet
        ME.Powerplant.Type = 'jet';
        
    case 11 % amphibious
        ME.Powerplant.Type = 'propeller';
        ME.Powerplant.Number = 2;
end


%% OTHERS
ME.Pressurization = NaN;
ME.Mission_Profile = NaN;


%% LOAD SIMILAR PLANES
switch ME.MissionType
    case  5 % business jet
        SP = importSimilarPlanes(ME.MissionType,CST,CF);
    case 11 % amphibious
        [SP, MV] = importSimilarPlanes(ME.MissionType,CST,CF);
end


%% CREATE DESIGN AIRCRAFT 
AC = aircraft();

% %% FUSELAGE SHAPE
%         ac=(2+1)*0.5+0.2;
%         af=ac(1+0.05)
%         lc = 
%         lf = lc +(af*4)
        AC.Fuselage.fusLength  = 24.7490;% 12.13+ME.Cargo.Volume/2.332;% A=3.286m^2: cilindric section; %Area form Catia
        AC.Fuselage.fusWidth   = 2.8797;%1.1*2.15;
        AC.Fuselage.fusHeight  = 3;
        AC.Fuselage.Volume     = AC.Fuselage.fusHeight*AC.Fuselage.fusWidth * AC.Fuselage.fusLength*0.8; % !!!!!!
        AC.Fuselage.frontArea  = 6.684;
        AC.Fuselage.la         = 11.78;
        AC.Fuselage.ln         = 3.169;
        AC.Fuselage.Swet       = 2*(1.797+2.053+25.564+26.313+1.212)+60.77; %60.77 es la parte relativa al hull
        AC.Fuselage.A_I        = 4.752;
        AC.Fuselage.A_II       = 22.116;
        AC.Fuselage.beta       = 6.095; % grados
        AC.Fuselage.cabLength  = 8.505;
        AC.Fuselage.cabWidth   = 0.95 * AC.Fuselage.fusWidth;
        AC.Fuselage.cabVolume  = AC.Fuselage.cabLength*3.286;
        ME.Cargo.Length = ME.Cargo.Volume/2.332;
        ME.Cargo.FloorArea = ME.Cargo.Length* AC.Fuselage.fusWidth;
        AC.Fuselage.cabinFrac  = (3.169+1.48)/AC.Fuselage.fusLength;
        AC.Fuselage.cabPos = AC.Fuselage.ln+1.48; 

        %% CG position
        DP.x_cg = 10;
        DP.y_cg = 0.5*AC.Fuselage.fusHeight;

%% EXAMPLE OF HOW TO OBTAIN MEAN VALUES FROM SIMILAR PLANES
% for i=1:length(SP)
%     if ~isempty(SP{i}.Actuations.Vcruise)
%         index(i)   = true; %#ok<SAGROW>
%     	vcruise(i) = SP{i}.Actuations.Vcruise; %#ok<SAGROW>
%     else
%         index(i)   = false; %#ok<SAGROW>
%         vcruise(i) = NaN; %#ok<SAGROW>
%     end
% end
% Vcruise = mean(vcruise(index));
% clear index vcruise i


%% CONTINUE...
run B_loadParameters.m
run C11_weightEstimation.m
run D11_airplaneDesignParameters.m
run E11_configurationDesign.m
% run F11_wingConfiguration.m