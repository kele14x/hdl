function Sig = satr(Sig0, bit)
%
if real(Sig0)==Sig0
    flagr=1;
else
    flagr=0;
end

Cntstr = 0;

if flagr==1
    Sig = Sig0;
    idx1 = find(Sig>(2^(bit-1)-1));
    Sig(idx1) = 2^(bit-1)-1;
    idx2 = find(Sig<-2^(bit-1));
    Sig(idx2) = -2^(bit-1);
    
    Cntstr = sum(idx1) + sum(idx2);
else
    SigR = real(Sig0);
    SigI = imag(Sig0);
    
    idx1 = find(SigR>(2^(bit-1)-1));
    SigR(idx1) = 2^(bit-1)-1;
    idx2 = find(SigR<-2^(bit-1));
    SigR(idx2) = -2^(bit-1);
    
    Cntstr = sum(idx1) + sum(idx2);

    idx1 = find(SigI>(2^(bit-1)-1));
    SigI(idx1) = 2^(bit-1)-1;
    idx2 = find(SigI<-2^(bit-1));
    SigI(idx2) = -2^(bit-1);
   
     Cntstr = Cntstr+ sum(idx1) + sum(idx2);

    Sig = SigR + 1i*SigI;
end

if Cntstr>0
    warning(strcat('Saturation happened!!',num2str(Cntstr)))
end
       
end

