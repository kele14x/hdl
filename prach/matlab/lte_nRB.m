function nRB = lte_nRB(BW)

if strcmpi(BW, '5')
    nRB = 25;
elseif strcmpi(BW, '10')
    nRB = 50;
elseif strcmpi(BW, '15')
    nRB = 75;
elseif strcmpi(BW, '20')
    nRB = 100;
else
    error(fprintf('Invalid BW: %s', BW));
end

end
