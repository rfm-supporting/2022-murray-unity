% unitylut_demo.m  Demonstrates how to use unitylut.m to make a Unity
%                  LUT texture that linearizes the mapping between RGB
%                  and luminance

clear; clc;

% here we make up some fictional calibration data: the achromatic RGB
% values shown on the screen, and the corresponding luminances measured
% from the VR headset
greylevel = round( linspace(0,255,10) );
lum = 100 * (greylevel/255).^2 + 5 + 0.1*randn(size(greylevel));

% number of samples requested for the LUT texture
nsamp = 32;

% filename for the LUT texture image
fname = 'lut_demo.png';

% create the LUT texture (saves image to file)
unitylut( greylevel, lum, 32, fname );
% - note: this function requires the Optimization Toolbox
