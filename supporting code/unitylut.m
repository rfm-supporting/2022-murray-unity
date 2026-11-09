function lut = unitylut( greylevel, lum, nsamp, filename )

% UNITYLUT  Use luminance calibration data to create a Unity LUT texture
%           that linearizes the relationship between RGB and luminance
%
% lut = unitylut( greylevel, lum, nsamp, filename )
% 
%   'greylevel' and 'lum' are the calibration data.
%   'nsamp' is the number of samples requested in the LUT texture (default 32).
%   'filename' is the filename with which the LUT texture will be saved (default 'lut.png').
% 
%   The return argument 'lut' is the LUT texture image.
% 
%   This function requires the Optimization Toolbox.

% 11-Nov-2021 -- created (RFM)
% 07-Jan-2022 -- revised gamma fit for supporting information (RFM)

% set default arguments
if nargin<3 || isempty(nsamp), nsamp = 32; end
if nargin<4, filename = 'lut.png'; end

% 1. fit the calibration data

% define a standard gamma function
gammafn = @( g, k, g0, gamma, delta ) k * power( (max(min(g,255),g0)-g0)/(255-g0), gamma ) + delta;

% fit the gamma function to the data
errfn = @( p ) sum( ( lum - gammafn(greylevel,p(1),p(2),p(3),p(4)) ).^2 );
pinit = [ max(lum)-min(lum) 0 2.2 min(lum) ];
pfit = fminsearch( errfn, pinit );
gammafit = @( x ) gammafn(x,pfit(1),pfit(2),pfit(3),pfit(4));

% plot the data and the fit
plot( greylevel, lum, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r' );
hold on
fplot( gammafit, [ 0 255 ], 'r-'  );
axis([ -5 260 0 1.2*max(lum) ]);
xlabel 'greylevel'
ylabel 'luminance (cd/m^2)'

% 2. create a LUT texture

% choose knot point x-coordinates
knot_x = linspace(0,255,nsamp);

% create a model of the LUT transformation. for a given choice of knot
% point y-values (knot_y), the model interpolates linearly between the
% knot points given by knot_x and knot_y. this is an approximation, as
% color grading in Unity sometimes shows small departures from linear
% interpolation.
lut_model = @( x, knot_y ) interp1( knot_x, knot_y, x );

% define a linear mapping between RGB and luminance
rgball = 0:255;
lumall = gammafit(255) * rgball/255;

% find knot point y-coordinates that make the LUT model as similar as
% possible to the linear mapping
errfn = @( knot_y ) sum( ( lumall - gammafit(lut_model(rgball,knot_y)) ).^2 );
knot_y_fit = fit_increasing( errfn, knot_x );

% create LUT texture
lut = rgb2lut( knot_y_fit );

% show predicted relationship between RGB and luminance with LUT in place;
% should be linear, except at low luminances that can't be displayed
knot_lum = gammafit( lut_model( knot_x, knot_y_fit ) );
plot( knot_x, knot_lum, 'bo', 'MarkerSize', 5, 'MarkerFaceColor', 'b' );
b = regress( knot_lum', knot_x' );
plot( [ 0 255 ], b*[ 0 255 ], 'b-' );
legend('calibration measurements','gamma fit','predicted RGB-to-luminance mapping with LUT in place','linear fit','Location','NorthWest');
hold off

% save LUT texture
if ~isempty( filename )
    imwrite( lut, filename );
end

end

function pfit = fit_increasing( errfn, pinit )
% FIT_INCREASING  Minimize an objective function subject to the
%                 constraints that in the fitted parameters pfit,
%                 we have that pfit(0) >= 0 and pfit(i) >= pfit(i-1)
nparam = numel(pinit);
A = -eye(nparam);
A(2:(nparam+1):end) = 1;
B = zeros([ nparam 1 ]);
options = optimoptions( 'fmincon', 'MaxFunctionEvaluations', 10000 );
pfit = fmincon( errfn, pinit, A, B, [], [], [], [], [], options );
end

function lut = rgb2lut( rgb )
% RGB2LUT  Create a Unity LUT texture from a vector of target RGB values

% count elements and reshape
n = numel( rgb );
x = reshape( rgb, [ 1 n ] );

% make n x n x n matrices with rgb channel responses
r = repmat( x, [ n 1 n ] );
g = repmat( flipud(x'), [ 1 n n ] );
b = repmat( reshape(x,[ 1 1 n ]), [ n n 1 ] );

% reshape matrices into a texture image
rt = reshape( r, [ n n*n ] );
gt = reshape( g, [ n n*n ] );
bt = reshape( b, [ n n*n ] );
lut = cat( 3, rt, gt, bt ) / 255;

end
