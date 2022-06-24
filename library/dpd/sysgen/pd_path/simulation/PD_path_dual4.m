function SigPD = PD_path_dual4(Sig, LUTd0, MSel, BandNum)
%%%%%%%%%%%%%%%%PA Modelling%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: eTunliu, 2017/07/06
% version 1.0: Power Amplifier Modelling, DualBand
% Input:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LUT:(16,12)
Idx =([1:2]==BandNum);
if Idx==0
    error('BandNum is not right!');
end
Xa = Sig(Idx,:);
Xb = Sig(~Idx,:);
LUTtmp = LUTd0(BandNum,:,:,:);
LUTd = reshape(LUTtmp,7,16,16);
MTap = size(MSel,1);
SNum = size(LUTd,3);

LenN = length(Xa)-MTap;

Y = zeros(1,LenN);
for nn = 1:LenN
    kk = 0;
    SumnI = 0;
    SumnQ = 0;

    for ii = 1:MTap
        for jj = 1:MTap
            if MSel(ii,jj)>0
                kk = kk+1; %kkth LUT
                
                % U15 or U16 bit15=0
                XaMagj = floor(abs(Xa(nn+jj)));
                XbMagj = floor(abs(Xb(nn+jj)));
                
                % get bit[11:14], U4,(4,0)
                XaMagIndj = floor(XaMagj/2^10)+1;
                XbMagIndj = floor(XbMagj/2^10)+1;
                
                if XaMagIndj>16
                    XaMagIndj=16;
                end
                if XbMagIndj>16
                    XbMagIndj =16;
                end
                
%                 XaMagIndj = satr(XaMagIndj, 4);
%                 XbMagIndj = satr(XbMagIndj, 4);

                % get bit[5:10] of XaMagj/XbMagj, U6,(6,6)
                XaMagdetaj = fix((XaMagj/2^10- (XaMagIndj-1))*2^6);
                XbMagdetaj = fix((XbMagj/2^10 - (XbMagIndj-1))*2^6);
                
                % IQ, Look up kkth LUT, IQ, (16,12)
                Tmplga0b0 = LUTd(kk, XaMagIndj,   XbMagIndj);
                Tmplga1b0 = LUTd(kk, XaMagIndj+1, XbMagIndj);
                Tmplga0b1 = LUTd(kk, XaMagIndj,   XbMagIndj+1);
                Tmplga1b1 = LUTd(kk, XaMagIndj+1, XbMagIndj+1);
                
%                 Tmplgadb0 = (Tmplga1b0-Tmplga0b0)*XaMagdetaj/2^6 + Tmplga0b0;
%                 Tmplgadb1 = (Tmplga1b1-Tmplga0b1)*XaMagdetaj/2^6 + Tmplga0b1;        
%                 Tmplg = (Tmplgadb1-Tmplgadb0)*XbMagdetaj/2^6 + Tmplgadb0;   
                
                %2D-Interpolation process,((16,12) - (16,12))*U5  + (16,12)
                %IQ,(16,12) - (16,12)=(17,12)
                Tmpsum1 = Tmplga1b0 - Tmplga0b0;                
                %IQ,(17,12)*(6,6) = (23,18)->(16,12)
                Tmpmpy1 = round(Tmpsum1*XaMagdetaj/2^6);
                Tmpmpy1 = satr(Tmpmpy1, 16);
                %IQ,(16,12) + (16,12) = (17,12)
                Tmplgadb0 = Tmpmpy1 + Tmplga0b0;
 
                %IQ,(16,12) - (16,12)=(17,12)
                Tmpsum2 = Tmplga1b1 - Tmplga0b1;                
                %IQ,(17,12)*(6,6) = (23,18)->(16,12)
                Tmpmpy2 = round(Tmpsum2*XaMagdetaj/2^6);
                Tmpmpy2 = satr(Tmpmpy2, 16);
                %IQ,(16,12) - (16,12) = (17,12)
                Tmplgadb1 = Tmpmpy2 + Tmplga0b1;
                
                %IQ,(17,12) - (17,12)=(18,12)
                Tmpsum3 = Tmplgadb1 - Tmplgadb0;
                %IQ,(18,12)*(6,6) = (24,18)->(19,12)->(16,12)
                Tmpmpy3 = round(Tmpsum3*XbMagdetaj/2^6);  
                Tmpmpy3 = satr(Tmpmpy3, 18);
                %IQ,(18,12) + (18,12)=(19,12)
                Tmplg = Tmpmpy3 + Tmplgadb0; 
                Tmplg = satr(Tmplg, 16);               
%                
                %I/Q S16,(16,0)
                Xai = real(Xa(nn + ii));
                Xaq = imag(Xa(nn + ii));
                %I/Q S16,(16,12)
                Tmplgi = real(Tmplg);
                Tmplgq = imag(Tmplg);
                %I/Q (16,0)*(16,12) - (16,0)*(16,12) = (33,12)
                TmpSumnI = Xai*Tmplgi - Xaq*Tmplgq;
                TmpSumnQ = Xai*Tmplgq + Xaq*Tmplgi;                
                SumnI = SumnI + TmpSumnI; % SumnI:(40,12)
                SumnQ = SumnQ + TmpSumnQ;
            end
        end
    end
    % (40,12)->(16,0)
%     SumnI = fix(SumnI/2^12);
%     SumnQ = fix(SumnQ/2^12);
    SumnI = round(SumnI/2^12);
    SumnQ = round(SumnQ/2^12);
    SumnI =  satr(SumnI, 16);
    SumnQ =  satr(SumnQ, 16);

    Y(nn) = SumnI + 1i*SumnQ;
end
 
SigPD = zeros(1,length(Xa));
SigPD((MTap+1)/2+1:end-(MTap-1)/2) = Y;

end