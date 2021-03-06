classdef aircraft < handle
    %AIRCRAFT A MATLAB class to contain the elementary data of an aircraft.
    %   Detailed explanation goes here
    
    properties (SetObservable)
        Manufacturer string         % The aircraft manufacturer
        Model        string         % The model of the aircraft
        FirstFlight  string         % First flight date (approximate)
        Height       double         % Maximum height [m]
        Length       double         % Maximum length [m]
        Wingspan     double         % Maximum wingspan [m]
        Wing         wing           % The main wing of the aircraft
        Wing1        wing           % Front wing
        Wing2        wing           % Rear wing
        VTP          wing           % Vertical stabilizer
        Engine       engines        % The engines of the aircraft
        Weight       weights        % The weights of the aircraft
        Payload      payload        % The payload/passengers
        Fuselage     fuselage       % The fuselage and cabin information
        Actuations   actuations     % The actuations of the aircraft
        Hull         hull           % Hull characteristics
        LandingGear  landingGear    % The landing gear
    end
    
    
    properties (Dependent, GetObservable)
    end
    
    
    methods
        % Constructor with listeners
        function obj = aircraft()
            obj.Wing        = wing();   
            obj.Wing1       = wing();          
            obj.Wing2       = wing();
            obj.VTP         = wing();
            obj.Weight      = weights(obj);
            obj.Engine      = engines(obj);
            obj.Payload     = payload();
            obj.Fuselage    = fuselage();
            obj.Actuations  = actuations();
            obj.Hull        = hull();
            obj.LandingGear = landingGear();
        end
        
    end
    
    
    methods (Static)
        % Update Total take-off thrust and MTOW ratio
        function TtoMTOWModification(~,~,varargin)
            if ~isempty(varargin{1}.Weight.MTOW)
                varargin{1}.Weight.Tto_MTOW = varargin{1}.Engine.TotalThrust/varargin{1}.Weight.MTOW;
            else
                varargin{1}.Weight.Tto_MTOW = [];
            end
        end
    end
    
end

