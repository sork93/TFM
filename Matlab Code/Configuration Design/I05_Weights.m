%************************************************************************************
%*																					*
%*					AIRCRAFT WEIGHTS CALCULATION SCRIPT								*
%*																					*
%************************************************************************************


%% WEIGHT SUBDIVISION:
options = optimoptions('fsolve',...
                       'StepTolerance',1e-9,...
                       'Display','none');


%Speed definitions
[~, asound, P, rho] = atmosisa(DP.CruiseAltitude);
V_D     = DP.MaxSpeed;  %Design dive speed
V_D_EAS = correctairspeed(V_D, asound, P, 'TAS', 'EAS');
Vapp_SP   = sqrt((loadFields(SP,'Actuations.Sl')'\(loadFields(SP,'Actuations.Vapprox').^2)').*DP.LFL);
VStall_L  = Vapp_SP/1.3; %[m/s]

% Ultimate Load
n_ult = getUltimateLoad(AC, AC.Wing, DP, CST, CF);

%AIRFRAME STRUCTURE:
    %Lead Wing group
    [WE.wing1,~,exitFlag,~]=fsolve(@(x)getWingWeight(x, AC, CST, AC.Wing1, V_D, VStall_L, n_ult, DP.delta_f),1e3,options);
    checkExitFlag(exitFlag);
    
    %Rear Wing group
    [WE.wing2,~,exitFlag,~]=fsolve(@(x)getWingWeight(x, AC, CST, AC.Wing2, V_D, VStall_L, n_ult, 0),1e3,options);
    checkExitFlag(exitFlag);
    
    % VTP
    WE.VTP = 0.64 * (n_ult*AC.VTP.Sw^2)^0.75;
    
    %Body group
    lt = (AC.Wing2.Root_LE-0.25*AC.Wing2.RootChord) - (AC.Wing1.Root_LE-0.25*AC.Wing1.RootChord); %Distance, fig D-2
    WE.fuselage = 0.23*sqrt(V_D_EAS*lt/(AC.Fuselage.fusWidth+AC.Fuselage.fusHeight))*AC.Fuselage.Swet^1.2;
    WE.fuselage = WE.fuselage*1.08; % 8% Fuselage penality for pressurized cabins
    WE.fuselage = WE.fuselage*1.04; % 4% Fuselage penality for fuselage-mounted engines
    WE.fuselage = WE.fuselage*1.07; % 7% Fuselage penality for main landing gear attached to the fuselage
    WE.fuselage = WE.fuselage*0.85; % 15% Fuselage reduction as indicated by Roskam Part I table 2.16 for composites/metal
    WE.fuselage = WE.fuselage*0.75; % 25% Fuselage reduction as indicated by MTorres
    
    %Alighting gear group
    %[Nose, Main]
    A = [5.4, 15.0];
    B = [0.049, 0.033];
    C = [0, 0.021];
    D = [0, 0];
    WE.undercarriageNose = (1.08 * (A(1) + B(1)*AC.Weight.MTOW^(3/4) + C(1)*AC.Weight.MTOW + D(1)*AC.Weight.MTOW^(3/2)));
    WE.undercarriageMain = (1.08 * (A(2) + B(2)*AC.Weight.MTOW^(3/4) + C(2)*AC.Weight.MTOW + D(2)*AC.Weight.MTOW^(3/2)));
    
    % Surface control group
    SCcockpit = 50; %50kg
    SCautopilot = 9*AC.Weight.MTOW^(1/5);
    SCsystems = 0.008 * AC.Weight.MTOW;    %Todos estos valores son funcion del MTOW, realmente habria que iterar
    WE.surfaceControls = SCcockpit + SCautopilot + SCsystems;

%PROPULSION GROUP:
    %Engines
    k_pg  = 1.15; %Jet transports podded engines
    k_thr = 1.18; %With thrust reversers installed
    WE.propulsionGroup = k_pg * k_thr * AC.Engine.Number * AC.Engine.Weight;
    
    % Engines installation and operation
    % Fuel systems
    % Thrust reversing probisions
    
    % Nacelles
    SwetNacelles = pi * AC.Engine.Diameter * 0.25*AC.Engine.Length;
    WE.nacelles = AC.Engine.Number * ...
                  (0.405 * sqrt(V_D_EAS) * SwetNacelles^1.3 + ...
                   0.05*AC.Engine.Weight + ...
                  (14.6+1.71+5.51)*SwetNacelles);
%     WE.nacelles1 = 0.055 * AC.Engine.TotalThrust/CST.GravitySI;
    

%AIRFRAME EQUIPMENT AND SERVICES
    % APUs
    k_apu  = 2;    %Installation factor 2-2.5
    k_wapu = 0.65; % Recent APU engines used on wide-body transports have a specific weight of only 65% of this value
    WE.APU = k_apu * k_wapu * 11.7 * (0.5*ME.HighDensityPassengers)^(3/5);

    % Instruments, navigational equipment & electronical groups
    
    
    % Hidraulic
    
    % Electronics
    
    % Furnishing
    
    % Air-conditioning
    
    % Anti-Icing
    
    
%FIXED EQUIPMENT
    % Fixed ballast
    % Fluids in a closed systems
%RENOVABLE EQUIPMENT
    % Passenger seats
    % Removable walls
    % Floor covering
    % Basic emergency equipment
% OPERATIONAL ITEMS
% PAYLOAD
% TOTAL FUEL


clear A B C D options k_pg k_thr lt asound rho P V_D V_D_EAS Vapp_SP VStall_L SwetNacelles
clear SCautopilot SCcockpit SCsystems n_ult exitFlag

%% USEFUL FUNCTIONS
function [Error] = getWingWeight(X, AC, CST, Wing, V_D, V_stall_L, n_ult, delta_f_L )
%Wing structural weight
%Inputs:
%	Wing: wing variable to get weight
%	V_D: Diving speed in EAS --> EAS=TAS·sqrt(rho/rho0)
%   Wdes: maximum weight with wing fuel tanks empty or maximum zero fuel weight

EstimatedTotalWeight = X;

%Suponiendo todo el combustible en las alas
Wdes = (AC.Weight.MTOW-AC.Weight.MFW)*CST.GravitySI;

% Skin joints factor
k_no = 1 + sqrt(1.905/Wing.WingSpan);

%Taper factor
k_taper = (1+Wing.TaperRatio)^0.4;

% Engines
k_e = 1.0; % 2 engines mounted 1 if  no engines

% Undercarriage
k_uc = 0.95; %no undercarriage

% Stifnnes against flutter
k_st = 1+9.06e-4*((Wing.WingSpan*cosd(Wing.Sweep_LE))^3/Wdes)*(V_D/100/Wing.Airfoil.t_c)^2*cosd(Wing.Sweep_12); % Low subsonic

% Struts 
k_b = 1; % no hay struts

%Basic Weight:
W_w_basic = 4.58e-3*k_no*k_taper*k_e*k_uc*k_st*...
    (k_b*n_ult*(Wdes-0.8*EstimatedTotalWeight))^0.55*...
    Wing.WingSpan^1.675*Wing.Airfoil.t_c^(-0.45)*(cosd(Wing.Sweep_12))^(-1.325);

%High lift devices:
k1 = 1.30;
	%k1=1.30: Double slotted Fowler
	%k1=1.45: Triple slotted Fowler
k2 = 1.25;
	%k2=1.00: Slotted flaps with fixed vane
	%k2=1.25: Double slotted flaps with variable geometry
kf = k1*k2;
bfs = 2*(Wing.eta_outboard-Wing.eta_inboard)*Wing.WingSpan/2;
W_tef = Wing.Swf*2.706*kf*(Wing.Swf*bfs)^(3/16)*...
    ((1.8*V_stall_L/100)^2*sind(delta_f_L)*cosd(Wing.Sweep_RE)/Wing.Airfoil.t_c)^(3/4);

%Spoilers:
W_sp = 12.2*Wing.Sw;

% Total Weight:
TotalWeight = W_w_basic + 1.2*(W_tef+W_sp);

Error = TotalWeight-EstimatedTotalWeight;
end

function n_ult = getUltimateLoad(AC, Wing, DP, CST, CF)
    % Getting the limit load
    [~, asound, P, rho] = atmosisa(DP.CruiseAltitude);
    [~, ~, ~, rho0] = atmosisa(0);
    
    %Suponiendo todo el combustible en las alas
    Wdes = (AC.Weight.MTOW-AC.Weight.MFW)*CST.GravitySI;
    
    %Load Factor for limit maneuvering
        n = 2.1+(24e3/(10e3+AC.Weight.MTOW*CF.kg2lbm));
        if n<2.5
            n = 2.5;
        elseif n>3.8
            n = 3.8;
        end
        
    %Load gust Factor 
    mu = 2*(Wdes/Wing.Sw)/(rho*Wing.CL_alpha_wf*Wing.CMA*CST.GravitySI);
    kg = 0.88*mu/(5.3+mu);
    V_EAS =  correctairspeed(DP.CruiseSpeed, asound, P, 'TAS', 'EAS');
    if DP.CruiseAltitude*CF.m2ft<20e3
        U_EAS = 50*CF.ft2m;
    elseif DP.CruiseAltitude*CF.m2ft>=20e3
        U_EAS = ((50 + (DP.CruiseAltitude*CF.m2ft-20e3)*(25-50)/(50e3-20e3)))*CF.ft2m;
    end
    ngust = 1 + kg*Wing.CL_alpha_wf*rho0*U_EAS*V_EAS*Wing.Sw/(2*Wdes);
    %Most limiting:
    n_ult = 1.5*max([n, ngust]);

end

function [] = checkExitFlag(exitFlag)
    if exitFlag ~= 1
        disp('Problema con la convergencia del solver')
        error('Problema con la convergencia')
    end
end