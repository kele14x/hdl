function d = std_pwr(x)

d = sqrt( sum( abs(x).^2 ) / length(x) );
