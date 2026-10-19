function Corrige_Perfil
clear
close all
resol=get(0,'ScreenSize');
xresol=resol(3);
yresol=resol(4);
[nome]=uigetfile('*.*','Selecione o arquivo de dados');
if nome==0
    return
end
airf=dlmread(nome,'',1,0);
corda=max(airf(:,1))-min(airf(:,1));
[ataque,ile]=min(airf(:,1));
x=(airf(:,1)-ataque)/corda;
n=length(x);
if abs(x(1)-1)>1e-3 | abs(x(n)-1)>1e-3
    h=warndlg('Os dados da seção não estão ordenados do bordo de fuga ao bordo de fuga!');
    waitfor(h);
    return
end
altura=airf(ile,2);
y=(airf(:,2)-altura)/corda;
x_ori=x;
y_ori=y;
[temp,ile]=min(x);
h=figure('Position',[xresol/4,yresol/4,xresol/2,yresol/2]);
plot(x,y,'.r'),axis('equal')
legend('original')
title('Seção de Aerofólio')
xlabel('x/c')
ylabel('y/c')
RPT=opta('Dezeja redistribuir os pontos?','Sim','Não');
close(h)
if RPT==1
    def={'401'};
    answer=inputdlg({'Número de pontos:'},' ',1,def);
    if max(size(answer))==0
        answer=def;
    end
    m=2*round(0.5*str2num(answer{1}))+1;
    i=(1:m)';
    REF=opta('Tipo de refinamento:','Só bordo de ataque','Bordo de ataque e de fuga');
    if REF==2
        xo=0.5*(1-sin(2*pi*(i-1)/(m-1)-pi/2));
    else
        xo=(1-sin(pi*(i-1)/(m-1)));
    end
    [temp,ile]=min(x);
    isu=find(x<=0.1);
    [temp,ole]=min(xo);
    osu=find(xo<=0.01);
    yo(1:ole,1)=interp1(x(1:ile),y(1:ile),xo(1:ole),'cubic');
    yo(ole:m,1)=interp1(x(ile:n),y(ile:n),xo(ole:m),'cubic');
    xo(osu)=interp1(y(isu),x(isu),yo(osu),'cubic');
    h=figure('Position',[xresol/4,yresol/4,xresol/2,yresol/2]);
    plot(x,y,'*r',xo,yo,'-bx'),axis('equal')
    legend('original','interpolado')
    title('Seção de Aerofólio')
    xlabel('x/c')
    ylabel('y/c')
    RP=opta('Usar redistribuição?','Sim','Não');
    close(h);
    if RP==1
        n=m;
        ile=ole;
        x=xo;
        y=yo;
        x_ori=x;
        y_ori=y;
    end
end
dy=diff(y)./diff(x);
ddy=diff(dy)./diff(x(1:n-1));
dy=(atan(atan(dy))/max(abs(atan(atan(dy)))));
ddy=(atan(atan(ddy))/max(abs(atan(atan(ddy)))));
%Figuras
figure('Position',[0,0,resol(3)/2,resol(4)/2],...
    'Name','SEÇÃO DE AEROFÓLIO','NumberTitle','off')
figure('Position',[resol(3)/2,resol(4)/2,resol(3)/2,resol(4)/2.35],...
    'Name','INCLINAÇÃO','NumberTitle','off')
figure('Position',[resol(3)/2,0,resol(3)/2,resol(4)/2.35],...
    'Name','CURVATURA','NumberTitle','off')
figure(1)
plot(x,y,'b'),axis('equal')
legend('original')
%title('Seção de Aerofólio')
xlabel('x')
ylabel('y')
figure(2)
plot(x(2:n),dy,'-k')
axis([-0.01 1.01 min(dy) max(dy)])
%title('Inclinação')
xlabel('x/c')
ylabel('dy/dx')
figure(3)
plot(x(2:n-1),ddy,'-k')
axis([-0.01 1.01 min(ddy) max(ddy)])
%title('Curvatura')
xlabel('x/c')
ylabel('d^2y/dx^2')
RPT=opta('Iniciar a suavização?','Sim','Não');
if RPT==1
    prompt={'Número de iterações:','Pontos para a média:','Variação máxima (% da corda):'};
    dlg_title=' ';
    num_lines=1;
    def={'10','2','0.02'};
    answer=inputdlg(prompt,dlg_title,num_lines,def);
    if max(size(answer))==0
        answer=def;
    end
    itera=str2num(answer{1});
    nave=str2num(answer{2});
    n_med=max(2,round(nave));
    maxchange=str2num(answer{3});
    xba=0.1;
    while RPT==1
        h=waitbar(0,'Processando...');
        for k=1:itera
            waitbar(k/itera)
            for i=1+n_med:n-n_med
                i1=i-n_med;
                i2=i+n_med;
                delta=0.25;
                x1=(1-delta)*xba;
                x2=(1+delta)*xba;
                if x(i)<x1
                    [c,s,mu]=polyfit(y(i1:i2),x(i1:i2),2);
                    temp=polyval(c,y(i),[],mu);
                    comp=abs(temp-x_ori(i))<maxchange/100;
                    x(i)=comp*temp+(1-comp)*(x_ori(i)+sign(temp-x_ori(i))*maxchange/100);
                end
                if x(i)>x2
                    [c,s,mu]=polyfit(x(i1:i2),y(i1:i2),2);
                    temp=polyval(c,x(i),[],mu);
                    comp=abs(temp-y_ori(i))<maxchange/100;
                    y(i)=comp*temp+(1-comp)*(y_ori(i)+sign(temp-y_ori(i))*maxchange/100);
                end
                if x(i)>=x1 & x(i)<=x2
                    [c,s,mu]=polyfit(y(i1:i2),x(i1:i2),2);
                    temp=polyval(c,y(i),[],mu);
                    temp=x(i)+(x2-x(i))/(x2-x1)*(temp-x(i));
                    comp=abs(temp-x_ori(i))<maxchange/100;
                    x(i)=comp*temp+(1-comp)*(x_ori(i)+sign(temp-x_ori(i))*maxchange/100);
                    [c,s,mu]=polyfit(x(i1:i2),y(i1:i2),2);
                    temp=polyval(c,x(i),[],mu);
                    temp=y(i)+(x(i)-x1)/(x2-x1)*(temp-y(i));
                    comp=abs(temp-y_ori(i))<maxchange/100;
                    y(i)=comp*temp+(1-comp)*(y_ori(i)+sign(temp-y_ori(i))*maxchange/100);
                end
            end
        end
        close(h)
        dy=diff(y)./diff(x);
        ddy=diff(dy)./diff(x(1:n-1));
        dy=(atan(atan(dy))/max(abs(atan(atan(dy)))));
        ddy=(atan(atan(ddy))/max(abs(atan(atan(ddy)))));
        %Figuras
        figure(1)
        plot(x_ori,y_ori,'b',x,y,'r'),axis('equal')
        legend('original','suavizado')
        %title('Seção de Aerofólio')
        xlabel('x')
        ylabel('y')
        figure(2)
        plot(x(2:n),dy,'-k')
        axis([-0.01 1.01 min(dy) max(dy)])
        %title('Inclinação')
        xlabel('x/c')
        ylabel('dy/dx')
        figure(3)
        plot(x(2:n-1),ddy,'-k')
        axis([-0.01 1.01 min(ddy) max(ddy)])
        %title('Curvatura')
        xlabel('x/c')
        ylabel('d^2y/dx^2')
        RPT=opta('Continuar com a suavização?','Sim','Não','Mudar parâmetros');
        if RPT==3
            prompt={'Número de iterações:','Pontos para a média:','Variação máxima (% da corda):'};
            dlg_title=' ';
            num_lines=1;
            itera=min(itera,10);
            def={num2str(itera),num2str(nave),num2str(maxchange)};
            answer=inputdlg(prompt,dlg_title,num_lines,def);
            if max(size(answer))==0
                answer=def;
            end
            itera=str2num(answer{1});
            nave=str2num(answer{2});
            n_med=max(2,round(nave));
            maxchange=str2num(answer{3});
            RPT=1;
        end
    end
end
close all
x=(x-min(x))/(max(x)-min(x)); %+ataque;
y=y/(max(x)-min(x));
h=figure('Position',[xresol/4,yresol/4,xresol/2,yresol/2]);
plot(x,y,'-b'),axis('equal')
title('Seção de Aerofólio')
xlabel('x/c')
ylabel('y/c')
RPT=opta('Salvar o resultado?','Sim','Não');
if RPT==1
    RPB=2;
    while RPB==2
        xt=x;
        yt=y;
        RP=opta('Cortar o bordo de fuga?','Sim','Não');
        RPB=1;
        if RP==1
            def={'0'};
            answer=inputdlg({'Percentual de espessura para o corte'},' ',1,def);
            if max(size(answer))==0
                answer=def;
            end
            corte=str2num(answer{1})/100;
            close all
            n=length(x);
            nf=round(n/10);
            xm=0.5*(x(nf:-1:1)+x(n-nf+1:n));
            ym=abs(y(nf:-1:1)-y(n-nf+1:n));
            xc=interp1(ym,xm,corte);
            if xc<=1
                yca=interp1(x(1:nf),y(1:nf),xc);
                ycb=interp1(x(n-nf+1:n),y(n-nf+1:n),xc);
                ind=find(x<xc);
                xt=[xc;x(ind);xc];
                yt=[yca;y(ind);ycb];
                xt=xt/(max(xt)-min(xt));
                yt=yt/(max(xt)-min(xt));
            else
                h=warndlg('A espessura pedida não existe. O corte no bordo de fuga não será feito.');
                waitfor(h);
            end
            h=figure('Position',[xresol/4,yresol/4,xresol/2,yresol/2]);
            plot(xt,yt,'-b'),axis('equal')
            title('Seção de Aerofólio')
            xlabel('x/c')
            ylabel('y/c')
            RPB=opta('Aceita?','Sim','Não');
            close(h)
            if RPB==1
                x=xt;
                y=yt;
            end
        end
    end
    corda_tmp=max(x)-min(x);
    [ataque_tmp,ile]=min(x);
    x=(x-ataque_tmp)/corda_tmp;
    altura_tmp=y(ile);
    y=(y-altura_tmp)/corda_tmp;
    RPT=opta('Restaurar dimensões originais?','Sim','Não');
    if RPT==1
        x=x*corda+ataque;
        y=y*corda+altura;
    else
        def={'1'};
        answer=inputdlg({'Comprimento da corda:'},' ',1,def);
        if max(size(answer))==0
            answer=def;
        end
        close all
        corda=str2num(answer{1});
        x=x*corda;
        y=y*corda;
    end
    z=zeros(size(x));
    airf=[x y z]';
    h=figure('Position',[xresol/4,yresol/4,xresol/2,yresol/2]);
    plot(x,y,'-b'),axis('equal')
    title('Seção de Aerofólio')
    xlabel('x/c')
    ylabel('y/c')
    %gp=find(nome=='.',1)-1;
    %gs=find(nome=='_',1)-1;
    %gt=1;
    %if length(gs)==1
    %gp=gs;
    %gt=str2num(nome(gs+2))+1;
    %end
    %nome=strcat(nome(1:gp),'_',num2str(gt),'.dat');
    [nome]=uiputfile('*.*','Nome para o arquivo de dados');
    if nome==0
        close all
        return
    end
    fid=fopen(nome,'wt');
%     fprintf(fid,'%+12.9e,%+12.9e,%+12.9e\n',airf);
    for k=1:length(x)
    fprintf(fid,'%g %g \n',x(k),y(k));
    end
    fclose(fid);
end
close all

%%#########################################################################
%  BEGIN  :  local function opta
%%#########################################################################
function k = opta(xHeader,varargin);
%MENU   Generate a menu of choices for user input.
%   CHOICE = MENU(HEADER, ITEM1, ITEM2, ... ) displays the HEADER
%   string followed in sequence by the menu-item strings: ITEM1, ITEM2,
%   ... ITEMn. Returns the number of the selected menu-item as CHOICE,
%   a scalar value. There is no limit to the number of menu items.
%
%   CHOICE = MENU(HEADER, ITEMLIST) where ITEMLIST is a string cell
%   array is also a valid syntax.
%
%   On most graphics terminals MENU will display the menu-items as push
%   buttons in a figure window, otherwise they will be given as a numbered
%   list in the command window (see example, below).
%
%   Command window example:
%   >> K = menu('Choose a color','Red','Blue','Green')
%   displays on the screen:
%
%     ----- Choose a color -----
%
%        1) Red
%        2) Blue
%        3) Green
%
%        Select a menu number:
%
%   The number entered by the user in response to the prompt is
%   returned as K (i.e. K = 2 implies that the user selected Blue).
%
%   See also UICONTROL, UIMENU, GUIDE.

%   J.N. Little 4-21-87, revised 4-13-92 by LS, 2-18-97 by KGK.
%   Copyright 1984-2005 The MathWorks, Inc.
%   $Revision: 5.21.4.2 $  $Date: 2005/06/21 19:41:25 $

%=========================================================================
% Check input
%-------------------------------------------------------------------------
if nargin < 2,
    disp('MENU: No menu items to choose from.')
    k=0;
    return;
elseif nargin==2 & iscell(varargin{1}),
    ArgsIn = varargin{1}; % a cell array was passed in
else,
    ArgsIn = varargin;    % use the varargin cell array
end

%-------------------------------------------------------------------------
% Check computer type to see if we can use a GUI
%-------------------------------------------------------------------------
useGUI   = 1; % Assume we can use a GUI

if isunix,     % Unix?
    useGUI = length(getenv('DISPLAY')) > 0;
end % if

%-------------------------------------------------------------------------
% Create the appropriate menu
%-------------------------------------------------------------------------
if useGUI,
    % Create a GUI menu to aquire answer "k"
    k = local_GUImenu( xHeader, ArgsIn );
else,
    % Create an ascii menu to aquire answer "k"
    k = local_ASCIImenu( xHeader, ArgsIn );
end % if

%%#########################################################################
%   END   :  main function "menu"
%%#########################################################################

%%#########################################################################
%  BEGIN  :  local function local_ASCIImenu
%%#########################################################################
function k = local_ASCIImenu( xHeader, xcItems )

% local function to display an ascii-generated menu and return the user's
% selection from that menu as an index into the xcItems cell array

%-------------------------------------------------------------------------
% Calculate the number of items in the menu
%-------------------------------------------------------------------------
numItems = length(xcItems);

%-------------------------------------------------------------------------
% Continuous loop to redisplay menu until the user makes a valid choice
%-------------------------------------------------------------------------
while 1,
    % Display the header
    disp(' ')
    disp(['----- ',xHeader,' -----'])
    disp(' ')
    % Display items in a numbered list
    for n = 1 : numItems
        disp( [ '      ' int2str(n) ') ' xcItems{n} ] )
    end
    disp(' ')
    % Prompt for user input
    k = input('Select a menu number: ');
    % Check input:
    % 1) make sure k has a value
    if isempty(k), k = -1; end;
    % 2) make sure the value of k is valid
    if  (k < 1) | (k > numItems) ...
            | ~strcmp(class(k),'double') ...
            | ~isreal(k) | (isnan(k)) | isinf(k),
        % Failed a key test. Ask question again
        disp(' ')
        disp('Selection out of range. Try again.')
    else
        % Passed all tests, exit loop and return k
        return
    end % if k...
end % while 1

%%#########################################################################
%   END   :  local function local_ASCIImenu
%%#########################################################################

%%#########################################################################
%  BEGIN  :  local function local_GUImenu
%%#########################################################################
function k = local_GUImenu( xHeader, xcItems )

% local function to display a Handle Graphics menu and return the user's
% selection from that menu as an index into the xcItems cell array

%=========================================================================
% SET UP
%=========================================================================
% Set spacing and sizing parameters for the GUI elements
%-------------------------------------------------------------------------
MenuUnits   = 'points'; % units used for all HG objects
resol=get(0,'ScreenSize');
xresol=resol(3);
yresol=resol(4);
textPadding = [18 8];   % extra [Width Height] on uicontrols to pad text
uiGap       = 5;        % space between uicontrols
uiBorder    = 5;        % space between edge of figure and any uicontol
winTopGap =0.10*yresol; % gap between top of screen and top of figure **
winLeftGap=0.10*xresol; % gap between side of screen and side of figure **

% ** "figure" ==> viewable figure. You must allow space for the OS to add
% a title bar (aprx 42 points on Mac and Windows) and a window border
% (usu 2-6 points). Otherwise user cannot move the window.

%-------------------------------------------------------------------------
% Calculate the number of items in the menu
%-------------------------------------------------------------------------
numItems = length( xcItems );

%=========================================================================
% BUILD
%=========================================================================
% Create a generically-sized invisible figure window
%------------------------------------------------------------------------
menuFig = figure( 'Units'       ,MenuUnits, ...
    'Visible'     ,'off', ...
    'NumberTitle' ,'off', ...
    'Name'        ,' ', ...
    'Resize'      ,'off', ...
    'Colormap'    ,[], ...
    'Color'    ,[1 1 0], ...
    'Menubar'     ,'none',...
    'Toolbar' 	,'none',...
    'CloseRequestFcn','set(gcbf,''userdata'',0)');

%------------------------------------------------------------------------
% Add generically-sized header text with same background color as figure
%------------------------------------------------------------------------
hText = uicontrol( ...
    'FontSize'    ,11, ...
    'style'       ,'text', ...
    'string'      ,xHeader, ...
    'units'       ,MenuUnits, ...
    'Position'    ,[ 100 100 100 20 ], ...
    'Horizontal'  ,'center',...
    'BackGround'  ,get(menuFig,'Color') );

% Record extent of text string
maxsize = get( hText, 'Extent' );
textWide  = maxsize(3);
textHigh  = maxsize(4);

%------------------------------------------------------------------------
% Add generically-spaced buttons below the header text
%------------------------------------------------------------------------
% Loop to add buttons in reverse order (to automatically initialize numitems).
% Note that buttons may overlap, but are placed in correct position relative
% to each other. They will be resized and spaced evenly later on.

for idx = numItems : -1 : 1; % start from top of screen and go down
    n = numItems - idx + 1;  % start from 1st button and go to last
    % make a button
    hBtn(n) = uicontrol( ...
        'units'          ,MenuUnits, ...
        'FontSize'    ,10, ...
        'position'       ,[uiBorder uiGap*idx textHigh textWide], ...
        'callback'       ,['set(gcf,''userdata'',',int2str(n),')'], ...
        'string'         ,xcItems{n} );
end % for

%=========================================================================
% TWEAK
%=========================================================================
% Calculate Optimal UIcontrol dimensions based on max text size
%------------------------------------------------------------------------
cAllExtents = get( hBtn, {'Extent'} );  % put all data in a cell array
AllExtents  = cat( 1, cAllExtents{:} ); % convert to an n x 3 matrix
maxsize     = max( AllExtents(:,3:4) ); % calculate the largest width & height
maxsize     = maxsize + textPadding;    % add some blank space around text
btnHigh     = maxsize(2);
btnWide     = maxsize(1);

%------------------------------------------------------------------------
% Retrieve screen dimensions (in correct units)
%------------------------------------------------------------------------
oldUnits = get(0,'Units');         % remember old units
set( 0, 'Units', MenuUnits );      % convert to desired units
screensize = get(0,'ScreenSize');  % record screensize
set( 0, 'Units',  oldUnits );      % convert back to old units

%------------------------------------------------------------------------
% How many rows and columns of buttons will fit in the screen?
% Note: vertical space for buttons is the critical dimension
% --window can't be moved up, but can be moved side-to-side
%------------------------------------------------------------------------
openSpace = screensize(4) - winTopGap - 2*uiBorder - textHigh;
numRows = min( floor( openSpace/(btnHigh + uiGap) ), numItems );
if numRows == 0; numRows = 1; end % Trivial case--but very safe to do
numCols = ceil( numItems/numRows );

%------------------------------------------------------------------------
% Resize figure to place it in top left of screen
%------------------------------------------------------------------------
% Calculate the window size needed to display all buttons
winHigh = numRows*(btnHigh + uiGap) + textHigh + 2*uiBorder;
winWide = numCols*(btnWide) + (numCols - 1)*uiGap + 2*uiBorder;

% Make sure the text header fits
if winWide < (2*uiBorder + textWide),
    winWide = 2*uiBorder + textWide;
end

% Determine final placement coordinates for bottom of figure window
bottom = screensize(4) - (winHigh + winTopGap);

% Set figure window position
set( menuFig, 'Position', [winLeftGap bottom winWide winHigh] );

%------------------------------------------------------------------------
% Size uicontrols to fit everyone in the window and see all text
%------------------------------------------------------------------------
% Calculate coordinates of bottom-left corner of all buttons
xPos = ( uiBorder + [0:numCols-1]'*( btnWide + uiGap )*ones(1,numRows) )';
xPos = xPos(1:numItems)+(winWide-btnWide)/2-uiGap; % [ all 1st col; all 2nd col; ...; all nth col ]
yPos = ( uiBorder + [numRows-1:-1:0]'*( btnHigh + uiGap )*ones(1,numCols) );
yPos = yPos(1:numItems); % [ rows 1:m; rows 1:m; ...; rows 1:m ]

% Combine with desired button size to get a cell array of position vectors
allBtn   = ones(numItems,1);
uiPosMtx = [ xPos(:), yPos(:), btnWide*allBtn, btnHigh*allBtn ];
cUIPos   = num2cell( uiPosMtx( 1:numItems, : ), 2 );

% adjust all buttons
set( hBtn, {'Position'}, cUIPos );

%------------------------------------------------------------------------
% Align the Text and Buttons horizontally and distribute them vertically
%------------------------------------------------------------------------

% Calculate placement position of the Header
textWide = winWide - 2*uiBorder;

% Move Header text into correct position near the top of figure
set( hText, ...
    'Position', [ uiBorder winHigh-uiBorder-textHigh textWide textHigh ] );

%=========================================================================
% ACTIVATE
%=========================================================================
% Make figure visible
%------------------------------------------------------------------------
set( menuFig, 'Visible', 'on' );

%------------------------------------------------------------------------
% Wait for choice to be made (i.e UserData must be assigned)...
%------------------------------------------------------------------------
waitfor(gcf,'userdata')

%------------------------------------------------------------------------
% ...selection has been made. Assign k and delete the Menu figure
%------------------------------------------------------------------------
k = get(gcf,'userdata');
delete(menuFig)

%%#########################################################################
%   END   :  local function local_GUImenu
%%#########################################################################