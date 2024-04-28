function nRB = nr_nRB(BW)

if strcmpi(BW, '5')
    nRB = 25;
elseif strcmpi(BW, '10')
    nRB = 52;
elseif strcmpi(BW, '15')
    nRB = 79;
elseif strcmpi(BW, '20')
    nRB = 106;
elseif strcmpi(BW, '25')
    nRB = 133;
elseif strcmpi(BW, '30')
    nRB = 160;
else
    error(fprintf('Invalid BW: %s', BW));
end

end