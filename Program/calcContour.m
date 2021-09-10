function calcContour(image)
% Representa el contorno de la imagen 'image' que se encuentra en la ruta
% indicada por 'filename'.

% Obtención de los parámetros necesarios para la representación.
[step, minCoeff, maxCoeff, loop, zoom, centered, videoName] = setParam();

biggerStep = step*10;

extractedContour = cell2mat(bwboundaries(image, 8, 'noholes'));

figure
plot(extractedContour(:, 2), - extractedContour(:, 1))
title('Prueba de correcto funcionamiento')

width = length(image(1, :));
height = length(image(:, 1));

% Obtención de las coordenadas y centrado de imagen en el origen.
x = width / 2 - extractedContour(:, 2);
y = height / 2 - extractedContour(:, 1);

% Cálculo de la FFT, resultado entre -pi y pi.
z_k = fftshift(fft(x + 1i*y));

% Número de muestras de la FFT.
L = length(z_k);

% Escalado que implica matemáticamente la FFT.
z_k = z_k / L;

% Generación de índices, depende de si 'fftLength' es par o impar.
if mod(L, 2) == 1
    indexes = (1:L)' - L/2 - 1/2;
else
    indexes = (1:L)' - L/2 - 1;
end

% Almacenamiento de los resultados ordenados, en la variable 'sheet'.
sheet = sortCoeff([indexes, abs(z_k), angle(z_k)]);
% writematrix(sheet, strcat(filename, '.xls'))

%% Representación y generación del vídeo
figure

% La animación es generada en Full HD (y el vídeo si se requiere).
set(gcf, 'Position', [0 0 1920 1080])
hold on; box on; axis equal

% Si se especifica que el vídeo esté centrado en el origen, ajusta los
% límites acorde a ello. De lo contrario, durante la ejecución irán
% cambiando para centrarse en el pincel.
if centered
    set(gca, 'xlim', [-width * 0.6, width * 0.6], 'ylim', [-height * 0.6, height * 0.6])
end

% Creamos el vídeo.
video = VideoWriter(strcat(videoName,'.mp4'), 'MPEG-4');
video.FrameRate = 60;
open(video);

% Prealojamiento de memoria para mejorar el rendimiento.
resLength   = length(0 : step : 2*pi);
eachCircle  = 0 : biggerStep : 1;
circleBox   = zeros(length(eachCircle), resLength, maxCoeff);
centre      = zeros(resLength, 1);
centreBox   = zeros(resLength, maxCoeff + 1); % Para incluir el origen
contourLine = zeros(resLength, 1);

% Cálculo y almacenamiento de las circunferencias, centros y radios.
% También representación de los mismos, si procede.
for coeff = 1:maxCoeff % Cada iteración es un nuevo coeficiente.
    for whole = 0:step:loop % Tantas vueltas como indique 'loop'.
        if minCoeff < coeff
            cla
            texto = '$\textrm{Numero de coeficientes: }' + string(coeff) + '$';
            title(texto,'interpreter','latex','fontsize', 16)
        end
        
        whole_aux = round(whole / step + 1);
        
        % Centros (y radios)
        if coeff ~= 1
            centre(whole_aux) = sheet(coeff - 1, 2) * exp(1i * (sheet(coeff - 1, 1) * 2 * pi * whole + sheet(coeff - 1, 3)));
            centreBox(:, coeff) = centre + centreBox(:, coeff - 1);
        else
            centre(whole_aux) = 0; % El primer centro es el origen.
        end
        
        % Circunferencias
        for eachCoeff = 1:coeff
            if (eachCoeff == coeff) && (eachCoeff ~= 1)
                circle = centreBox(whole_aux, eachCoeff - 1) + sheet(eachCoeff - 1, 2) * exp(1i * 2 * pi * eachCircle);
                circleBox(:, whole_aux, eachCoeff) = circle;
            end
            if minCoeff < coeff
                plot(real(circleBox(round(eachCircle / biggerStep + 1), whole_aux, eachCoeff)), imag(circleBox(round(eachCircle / biggerStep + 1), whole_aux, eachCoeff)), 'Color', '#0c821a')
            end
        end
        
        % Genera un punto rojo en la punta del último círculo, que será el
        % centro del siguiente coeficiente.
        contourLine(whole_aux) = centreBox(whole_aux, coeff);
        
        % Si el coeficiente se encuentra entre los valores indicados para,
        % lleva a cabo la representación.
        if minCoeff < coeff
            % Centro de la última circunferencia
            plot(real(contourLine(1:whole_aux)), imag(contourLine(1:whole_aux)), '.', 'Color', 'red')
            
            % Resto de centros
            plot(real(centreBox(whole_aux, 1:coeff - 1)), imag(centreBox(whole_aux, 1:coeff - 1)), '.', 'Color', 'blue')
            
            % Radios
            plot(real(centreBox(whole_aux, 1:coeff)), imag(centreBox(whole_aux, 1:coeff)), 'Color', 'black')
            
            % Capturar gráfico y escribir en archivo
            if ~centered
                set(gca, 'xlim', [real(contourLine(whole_aux)) - width * 0.6 / zoom, real(contourLine(whole_aux)) + width * 0.6 / zoom], 'ylim', [imag(contourLine(whole_aux)) - height * 0.6 / zoom, imag(contourLine(whole_aux)) + height * 0.6 / zoom])
            end
            
            writeVideo(video, getframe(gcf));
        end
    end
end

close(video);

end