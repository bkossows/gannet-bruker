function [ MRS_struct ] = PhilipsRead_data(MRS_struct, fname, fname_water )


paras = textread(strcat(fileparts(fname),'/acqp'),'%s','delimiter','=');
filelength=size(paras);
for n=1:filelength(1);
    if strcmp(paras(n,1),'##$SW_h');
        bandwidth=str2num(paras{n+1,1});
    end
    if strcmp(paras(n,1),'##$SW');
        sw=str2num(paras{n+1,1});
    end
    if strcmp(paras(n,1),'##$ACQ_size')
        np=str2num(paras{n+2,1}); 
    end
    if strcmp(paras(n,1),'##$SFO1')
        reffrq=str2num(paras{n+1,1});
    end
    if strcmp(paras(n,1),'##$DECIM')
        decim=str2num(paras{n+1,1});
    end
    if strcmp(paras(n,1),'##$DSPFVS')
        dspfvs=str2num(paras{n+1,1});
        if(dspfvs<20 || dspfvs>23)
            fprintf('!!! Cannot determine how many points to skip (BRUKER DSP not recognized) !!! \n');
        end
    end
    if strcmp(paras(n,1),'##$GRPDLY')
        grpdly=str2num(paras{n+1,1});
    end
    if strcmp(paras(n,1),'##$DIGIMOD')
        digimod=str2num(paras{n+1,1});
    end
    if strcmp(paras(n,1),'##$NA')
        na=str2num(paras{n+1,1});
    end
end
   
   complx_points=(np/2);
    fileid=fopen(fname,'r');
    if fileid==-1
        fprintf('File ERROR!!!');
    end
    A = fread(fileid,'int32','n');
    status = fclose('all');
    fprintf('FIDs loaded \n');

    [fsize,c]=size(A);

    A_div=reshape(A,2,complx_points,na);
    A_complex=squeeze(A_div(1,:,:,:)-1i*A_div(2,:,:,:));
    A_complex=circshift(A_complex,-floor(grpdly)); %circular shift DSP filtered data
    %Gannet convention starts here
    
   MRS_struct.p.npoints = complx_points;
   MRS_struct.p.Navg(MRS_struct.ii) = na;
   MRS_struct.p.nrows=na;

   MRS_struct.p.coil_channels=1;
   
   MRS_struct.fids.data=A_complex;
   
  
   %%'Duplicated' code added in to handle .data water files
   % work out water data header name
   
   if nargin >2
    %TO DO inspect water length of the water filter
        fileid=fopen(fname_water,'r');
        if fileid==-1
            fprintf('File ERROR!!!');
        end
        A = fread(fileid,'int32','n');
        status = fclose('all');
        fprintf('FIDs loaded \n');

        [fsize,c]=size(A);

        A_div=reshape(A,2,complx_points);
        A_complex=squeeze(A_div(1,:)-1i*A_div(2,:));
        A_complex=circshift(A_complex,[0 -floor(grpdly)]); %circular shift DSP filtered data

           MRS_struct.fids.data_water = A_complex;
   end
   
  %Acquisition Parameters
    MRS_struct.p.sw=bandwidth; %This should be parsed from headers where possible
    MRS_struct.p.LarmorFreq=reffrq; %This should be parsed from headers where possible
    MRS_struct.p.ONOFForder='offfirst';
end

