% FastICA with User-Provided Mixed Signals

% Define your mixed signals as a matrix
mixedSignals = [
    1119 0321 0497 0054 0181 0542 0345 0149 0120 0415 0622 0315 0295 0142 0200 0516;
    1209 0382 0585 0153 0276 0609 0371 0241 0147 0494 0372 0518 0205 0132 0545 0354;
    1320 0208 0121 0412 0483 0175 0335 0515 0320 0188 0343 0532 0455 0604 0227 0153;
    1417 0548 0265 0279 0518 0122 0425 0216 0520 0119 0521 0101 0545 0415 0291 0258;
    0546 0151 0420 0570 0233 0404 0172 0424 0440 0387 0245 0113 0321 0605 0254 0572;
    1197 3576 0335 0440 0458 0197 0580 0382 0374 0358 0821 0248 0509 0170 0373 0335;
    1596 0236 0199 0467 0354 0337 0262 0532 0499 0494 0167 0498 0571 0217 0547 0296
];

% Plot the mixed signals
figure;
for i = 1:size(mixedSignals, 1)
    subplot(size(mixedSignals, 1), 1, i);
    plot(mixedSignals(i, :));
    title(['Mixed Signal ' num2str(i)]);
end

% Apply FastICA
% Add FastICA toolbox to path if not already added
% You can download it from: https://research.ics.aalto.fi/ica/fastica/
addpath('fastica');

% Run FastICA
[separatedSignals, A, W] = fastica(mixedSignals, 'numOfIC', size(mixedSignals, 1));

% Plot the separated signals
figure;
for i = 1:size(separatedSignals, 1)
    subplot(size(separatedSignals, 1), 1, i);
    plot(separatedSignals(i, :));
    title(['Separated Signal ' num2str(i)]);
end

% Results
disp('Mixing Matrix (Unknown):');
disp('Mixing matrix is not provided, only estimates available.');
disp('Estimated Mixing Matrix:');
disp(A);
disp('Estimated Separating Matrix:');
disp(W);

% Clean up
rmpath('fastica');
