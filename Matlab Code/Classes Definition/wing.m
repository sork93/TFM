classdef wing < handle
    %WING Summary of this class goes here
    %   Detailed explanation goes here
    % 
    % Mean Aerodynamic Chord (MAC - CMA) extra information:
    %   Rectangular wing: MAC = chordlength
    %   Deltawing: MAC = 2/3 inner cord length
    %   Trapezoid wing: MAC = 2/3 * innerchord * ((1+lambda+lambda^2)/(1+lambda)) --> (lambda = outerchord / innerchord)
    %   Elliptical wing: MAC = 8/3 * pi * innerchord
    %   MAC is used to have a dimensionless value for a position (like ca, cl...) for example: COG = 29% of MAC (this works for all wings, if MAC is calculated correctly)
    %
    
    properties
        Sw              double  %[double] Total Wing Surface [m^2]
        WingSpan        double  %[double] Span of the wing [m]
        RootChord       double  %[double] Chord at the root [m]
        TipChord        double  %[double] Chord ath the tip [m]
        CMA             double  %[double] Mean Aerodynamic Chord [m]
        CMG             double  %[double] Mean Geometric Chord [m]
        AspectRatio     double  %[double] Aspect Ratio (b/CMA) (b^2/Sw) [-]
        TaperRatio      double  %[double] Wing taper ratio (tipChord/rootChord) [-]
        Airfoil         string  %[double] Name of the used Airfoil [-]
        Sweep           double  %[double] Sweep of the wing at the point 1/4 of CMA [�]
        Dihedral        double  %[double] Dihedral of the wing [�]
        WingLoading     double  %[double] MTOW/Sw [kg/m^2]
    end
    
    methods
         % Class constructor
        function obj = wing(varargin)
        end
        
    end
    
end
