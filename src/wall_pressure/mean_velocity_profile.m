function [U,dUdy] = mean_velocity_profile(y,delta,u_t,fluid,inputs, dcpdxc,tau_w,delta_s)
% MEAN_VELOCITY_PROFILE  Perfil medio de velocidad U(y) de la capa limite para el
% modelo TNO: ley de la pared (lineal / logaritmica) + ley de la estela de Coles.
%
%   y        [m]   coordenadas normales a la pared (vector columna)
%   delta    [m]   espesor de capa limite (ya multiplicado por 1.2 en TNO.m)
%   u_t      [m/s] velocidad de friccion
%   dcpdxc   [-]   dCp/d(x/c) en la estacion de muestreo (XFOIL)
%   tau_w    [Pa]  esfuerzo cortante en la pared
%   delta_s  [m]   espesor de desplazamiento
%   U, dUdy        perfil [m/s] y su derivada [1/s]
%
% inputs.tno_perfil selecciona como se obtiene el parametro de estela Pi_w:
%   'original' (defecto) codigo original de UTwente, tal cual venia en el zip:
%              Pi_w = 0.8*(beta+0.5)^(3/4) con beta = delta_s/tau_w * dCp/dx / c.
%              NOTA: en esta expresion beta no lleva la presion dinamica
%              (0.5*rho*U^2), por lo que resulta ~0 y Pi_w ~ 0.48 en todos los
%              casos. Se mantiene sin cambios para reproducir los resultados
%              publicados. Ver documentation/HALLAZGO_TNO.md.
%   'coles'    cierre de Coles: Pi_w tal que U(delta) = Ue (requiere inputs.Ue_lado
%              [m/s], que fija surface_pressure_spectrum). Opcion de DIAGNOSTICO,
%              no validada frente a medidas; no la usa ningun resultado del paper.
k = 0.38;
B = 5;
y_plus = y*u_t/fluid.ni;

modo = 'original';
if isfield(inputs,'tno_perfil') && ~isempty(inputs.tno_perfil), modo = char(inputs.tno_perfil); end
switch lower(modo)
    case 'original'
        dcpdx = dcpdxc*(1/inputs.chord);
        beta = delta_s/tau_w*dcpdx;
        Pi_w = 0.8*(beta+0.5)^(3/4);
    case 'coles'
        if ~isfield(inputs,'Ue_lado')
            error('mean_velocity_profile:sinUe', 'El modo ''coles'' requiere inputs.Ue_lado (lo fija surface_pressure_spectrum).');
        end
        Pi_w = max(0, (inputs.Ue_lado/u_t - (1/k)*log(delta*u_t/fluid.ni) - B)*k/2);
    otherwise
        error('mean_velocity_profile:modo', 'inputs.tno_perfil debe ser ''original'' o ''coles''.');
end

%% for the inner layer
u_plus(y_plus<5) = y_plus(y_plus<5);

%% for the outer layer
u_plus(y_plus>5) = (1/k)*log(y_plus(y_plus>5))+B+(2*Pi_w/k)*sin(pi*y(y_plus>5)/(2*delta)).^2;
u_plus = u_plus';
%% Streamwise velocity
U = u_plus*u_t;

%% derivative
dUdy = diff(U)./diff(y);
dUdy(end+1) = (U(end)-U(end-1))/(y(end)-y(end-1));
end
