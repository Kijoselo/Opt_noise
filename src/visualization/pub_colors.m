function c = pub_colors()
% PUB_COLORS  Paleta estandar del paper (tonalidad unica en todas las figuras).
% Convencion acordada: BASELINE = naranja, OPTIMIZADO = azul (igual que la
% figura de espectro de pala que se insertara). Colores base de MATLAB para
% maxima compatibilidad y calidad de impresion.
c = struct();
c.base   = [0.8500 0.3250 0.0980];   % naranja  -> baseline / perfil base
c.opt    = [0.0000 0.4470 0.7410];   % azul     -> optimizado
c.third  = [0.4660 0.6740 0.1880];   % verde    -> tercera serie (p.ej. delta)
c.gray   = [0.5000 0.5000 0.5000];   % gris     -> referencias/auxiliares
c.acc    = [0.4940 0.1840 0.5560];   % morado   -> acento adicional
% orden de ejes por defecto: base, opt, luego el resto
c.order  = [c.base; c.opt; c.third; c.acc; c.gray];
end
