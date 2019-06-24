function [] = urpec_writeJob(config)
%urpec_writeJob creates a job file using proximity effect corrected .dxf file generated by urpec
%   Job files are created by editing a job fie template. Currently, the
%   only supported template is for NPGS, but others can be added with ease.
%   Function works by opening job file template and doing a search and
%   replace for the various config fields, so adding relevant parameters to
%   new job files is trivial.
%
%   IMPORTANT NOTE FOR NPGS JOBS: The dwell time associated with the area
%   dose does not get autoupdated from the template value when generating the job file. One could code this in, as it is
%   proportional to the dose and current, but it will automatically update
%   when the user inputs the measured current during the write, which
%   he/she should do prior to writing anyways. For this reason, it can be
%   ignored in the job file. One may also want to remember to add/edit aperture offsets
%   during the write.
%
%
%   config is a struct with the following optional fields:
%       dxf (string): .dxf file
%       platform (string): specifies software for EBL. Currently only supports
%       'NPGS'
%       template (string): template for run file. NGPS run files are
%       .RF6
%       dtc (string): dose to clear in uC/cm^2
%       init_move_x (string): initial stage movement in x direction
%       init_move_y (string): initial stage movement in y direction
%       final_move_x (string): final stage movement in x direction
%       final_move_y (string): final stage movement in y direction
%       am_aperture (double): size of aperture for small features inc
%       microns (relies on aperture position numbering in SEM...)
%       lg_aperture (double): size of aperture for large features in
%       microns (relies on aperture position numbering in SEM...)
%       al_mag_sm (string): magnification for small alignment
%       al_mag_med (string): magnification for medium alignment
%       al_mag_lg (string): magnification for coarse alignment
%       write_mag_sm (string): magnification for writing small features
%       write_mag_lg (string): magnification for writing large features
%
%
%   Example config for 6 entity NPGS job file doing a 3 mag alignment and 2 aperture/2 mag write:
%       config=struct;
%       config.platform = 'NPGS'
%       config.template = 'Job_NPGS_6Entity_Template.RF6'
%       config.dtc = '400'
%       config.init_move_x = '105'
%       config.init_move_y = '-12'
%       config.final_move_x = '-747'
%       config.final_move_y = '-123'
%       config.am_aperture = 7.5
%       config.lg_aperture = 30
%       config.al_mag_sm = '1500'
%       config.al_mag_med = '800'
%       config.al_mag_lg = '235'
%       config.write_mag_sm = '1500'
%       config.write_mag_lg = '600'
%
%
% Elliot Connors (econnors@ur.rochester.edu) 3/2019


% --------------------------------------
% CONFIG
% --------------------------------------

%TODO:
% 1. Dose array config/template

if ~exist('config','var')
    config=struct();
end

if ~isfield(config,'template')
    display('Please select a template file...');
    [config.template temppath] = uigetfile('C:\NPGS\Projects\RunFilesFromMATLAB\Templates\*.RF6');
    fulltempfile = fullfile(temppath, config.template);
end

temp_ind = regexp(config.template,'\');
if ~isempty(temp_ind)
    templateID = config.template(max(temp_ind)+1:end-4);
else
    templateID = config.template(1:end-4);
end

switch templateID
    
    case 'NG_PatternOnly'
        display(['Creating job using ' templateID]);
        
       % default values for this template (based on Si devices on 3/12/19)
        config = def(config,'dtc','300');
        config = def(config,'sm_aperture',7.5);
        config = def(config,'lg_aperture',60);
        config = def(config,'write_mag_sm','1500');
        
        switch config.sm_aperture
            case 30
                sm_aperture_current = '445.0';
                sm_aperture = '1';
                
            case 7.5
                sm_aperture_current = '17.0';
                sm_aperture = '2';
                
            case 10
                sm_aperture_current = '38.0';
                sm_aperture = '3';
                
            case 40
                sm_aperture_current = '600';
                sm_aperture = '4';
                
            case 60
                sm_aperture_current = '1400';
                sm_aperture = '5';
                
            case 120
                sm_aperture_current = '6000';
                sm_aperture = '6';
                
        end
        
        switch config.lg_aperture
            case 30
                lg_aperture_current = '445.0';
                lg_aperture = '1';
            case 7.5
                lg_aperture_current = '17.0';
                lg_aperture = '2';
            case 10
                lg_aperture_current = '38.0';
                lg_aperture = '3';
            case 40
                lg_aperture_current = '600';
                lg_aperture = '4';
            case 60
                lg_aperture_current = '1400';
                lg_aperture = '5';
            case 120
                lg_aperture_current = '6000';
                lg_aperture = '6';
        end

        config = def(config,'write_mag_sm','1500');
        
        % select dose file
        display('Please choose layer doses...');
        [baseName, folder] = uigetfile('C:\NPGS\Projects\*.txt');
        file_doses = fullfile(folder, baseName);
        doses_tab = readtable(file_doses);
        doses = doses_tab(:,1);
        doses = table2array(doses);
        
        % convert dose percentages to actual doses using config.dtc
        doses = doses*str2num(config.dtc);
        
        % choose .dc2 files
        display('Please choose CAD file...');
        [cad,dir] = uigetfile([folder '\*.dc2']);
        fullCad = fullfile(dir,cad);
        cad=cad(1:end-4);
        
         %find layers in use
        cad_t = fileread(fullCad);
        
        scad = strrep(cad_t,' ',''); % remove spaces
        ind = regexp(scad,'DoNotUse'); %find index... layers are right after
        scad = scad(ind:ind+1000); %shorten
        scad(isspace(scad))='x'; %replace blanks with 'x'
        indstart = 9;% starting layers index
        indend = min(regexp(scad,'x212'))-1; %ending layers index
        slstr = scad(indstart:indend); %string of layers used separated with x's
        ind_list = regexp(slstr,'xx'); %list of x locations
        ind_list = ind_list(2:end); % skip layer 0
        slayers = {};
        for i = 1:length(ind_list)
            if i<length(ind_list)
                slayers{length(slayers)+1} = slstr(ind_list(i)+2:ind_list(i+1)-1);
            else
                slayers{length(slayers)+1} = slstr(ind_list(end)+2:end-1);
            end
        end
        %EJC: 4/10/19 added this because was getting issue where more
        %things are accidentally getting recognized as layers... this is
        %not perfect either though... maybe need to find more robust way to
        %pull out layers used
        good = 1;
        for i = 1:length(slayers)
            if good
                if length(slayers{i})>2
                    slayers = slayers(1:i-1);
                    good = 0;
                end
            end
        end
        
        f = input('Please enter run file filename without a file extension (example: DD_L2_SiGe).' ,'s');
        RunFile_Name = strcat(f,'.RF6');
        Path1 = ['C:\NPGS\Projects\RunFilesFromMATLAB\', RunFile_Name];
        Path2 = [dir, RunFile_Name];
        
        %This ensures we always have an unedited file that can take inputs
        savdir = 'C:\NPGS\Projects\RunFilesFromMATLAB\TemplateArchive';
        copyfile(fulltempfile,savdir);
        copyfile(['C:\NPGS\Projects\RunFilesFromMATLAB\Templates\' templateID '.RF6'], Path1);
        
        %read template and replace proper fields
        f = fileread(Path1);
        
        %colortab from urpec
        ctab={[1 0 0] [0 1 0] [0 0 1] [1 1 0] [1 0 1] [0 1 1] [1 0 0] [0 1 0] [0 0 1] [1 1 0] [1 0 1] [0 1 1] [1 0 0] [0 1 0] [0 0 1] [1 1 0] [1 0 1] [0 1 1]  };
        colorstrings = {};
        for i=1:length(ctab)
            ctabmat = 255.*ctab{i};
            colorstrings{i} = {[num2str(ctabmat(1)) ' ' num2str(ctabmat(2)) ' ' num2str(ctabmat(3))]};
            colorstrings{i} = strrep(colorstrings{i},'0','000');
        end
        
         % generate pattern writing text
        %small
        slogic={}; % logical cell array if layer name exists
        for i=1:length(doses)
            if any(strcmp(slayers,num2str(i)))
                a = 1;
            else
                a = 0;
            end
            slogic{i} = a;
        end
        sdose = [];
        scol = {};
        for i=1:length(slogic)
            if slogic{i}
                sdose(end+1) = doses(i);
                scol{end+1} = colorstrings{i};
            end
        end
        tot_str_s = '';
        nextnum = 2; %layer numbering starts at 2 and goes up with patterns created with urpec
        for i=1:length(slayers)
            strline1 = ['lev_' slayers{i} ' ' num2str(nextnum) ' w    0,0    29106    ' config.write_mag_sm '    42.2974    42.2974    ' sm_aperture '     ' sm_aperture_current];
            strline2 = ['col -001 ' char(scol{i}) ' 10.5239 ' num2str(sdose(i)) ' 0'];
            if i==1
            sm_str = sprintf('lev_%s %s w    0,0    29106    %s    42.2974    42.2974    %s     %s\ncol -001 %s 10.5239 %s 0',...
                slayers{i}, num2str(nextnum), config.write_mag_sm, sm_aperture, sm_aperture_current, char(scol{i}), num2str(sdose(i)));
            else
                %sm_str = sprintf('%s\nlev_%s %s w    0,0    29106    %s    42.2974    42.2974    %s     %s\ncol -001 %s 10.5239 %s 0',...
                %sm_str, slayers{i}, num2str(nextnum), config.write_mag_sm, sm_aperture, sm_aperture_current, char(scol{i}), num2str(sdose(i)));
            end
            nextnum = nextnum + 1;
            if i==1
                tot_str_s = strline1;
            else
                %tot_str_s = [tot_str_s newline strline1];
                tot_str_s=sprintf('%s\r\n%s',tot_str_s,strline1);
            end
            %tot_str_s = [tot_str_s newline strline2];
            tot_str_s=sprintf('%s\r\n%s',tot_str_s,strline2);
        end
        %tot_str_s = sm_str;
        
        %replace text
        f = strrep(f,'writing',tot_str_s);
        f = strrep(f,'cad',cad);
        
        fid = fopen(Path1,'w');
        fprintf(fid,f);
        fclose(fid);
        
        %place file in project directory
        copyfile(Path1, Path2);
        
        %Code to convert mixed terminator file to CRLF DOS formatting
        %get unix path
        %ind = [regexp(dir,'\')];
        %projFolder = dir(ind(end-1)+1:end-1);
        %unixpath = ['/mnt/c/NPGS/Projects/' projFolder '/' RunFile_Name];
        
        %convert to fix for dos formatting
        %success = system(['bash -c ''unix2dos ' unixpath '''']);
        %if success == 0
        %    display('Conversion from unix to dos successful.');
        %else
        %    display('Conversion failed from unix to dos... Run file may not be editable in NPGS Run File Editor');
        %end
        %copy corrected file back to run files from matlab dir
        copyfile(Path2,Path1);
        
        display(['Run file ' RunFile_Name ' created in ' Path2 ' with a backup created in ' Path1])
        
    
    case 'NG_StandardWrite'%'job_NPGS_NG_StandardWrite_Template'
        display(['Creating job using ' templateID]);
        
        
        
        substrate = input('Enter 1 for Si and 2 for GaAs: \n');
        switch substrate
            case 1
        % default values for this template (based on Si devices on 3/12/19)
        config = def(config,'dtc','400');
        config = def(config,'init_move_x','105');
        config = def(config,'init_move_y','-12');
        config = def(config,'final_move_x','-747');
        config = def(config,'final_move_y','-123');
        config = def(config,'sm_aperture',7.5);
        config = def(config,'lg_aperture',30);
        config = def(config,'al_mag_sm','1500');
        config = def(config,'al_mag_med','800');
        config = def(config,'al_mag_lg','235');
        config = def(config,'write_mag_sm','1500');
        config = def(config,'write_mag_lg','600');
        
            case 2
      % default values for this template (for GaAs device 2019/04/18)
        config = def(config,'dtc','325');
        config = def(config,'init_move_x','47');
        config = def(config,'init_move_y','-105');
        config = def(config,'final_move_x','-847');
        config = def(config,'final_move_y','-23');
        config = def(config,'sm_aperture',7.5);
        config = def(config,'lg_aperture',60);
        config = def(config,'al_mag_sm','1500');
        config = def(config,'al_mag_med','500');
        config = def(config,'al_mag_lg','235');
        config = def(config,'write_mag_sm','1500');
        config = def(config,'write_mag_lg','235');
        
            otherwise
                error('Invalid number or character.');
                
        end
     
        
        
        % select dose files for sm/med/lg
        display('Please choose layer doses for small features...');
        [baseName, folder] = uigetfile('C:\NPGS\Projects\*.txt');
        file_sm_doses = fullfile(folder, baseName);
        sm_doses_tab = readtable(file_sm_doses);
        sm_doses = sm_doses_tab(:,1);
        sm_doses = table2array(sm_doses);
        
        display('Please choose layer doses for med features...');
        [baseName, folder] = uigetfile([folder '\*.txt']);
        file_med_doses = fullfile(folder, baseName);
        med_doses_tab = readtable(file_med_doses);
        med_doses = med_doses_tab(:,1);
        med_doses = table2array(med_doses);
        
        display('Please choose layer doses for lg features...');
        [baseName, folder] = uigetfile([folder '\*.txt']);
        file_lg_doses = fullfile(folder, baseName);
        lg_doses_tab = readtable(file_lg_doses);
        lg_doses = lg_doses_tab(:,1);
        lg_doses = table2array(lg_doses);
        
        % convert dose percentages to actual doses using config.dtc
        sm_doses = sm_doses*str2num(config.dtc);
        med_doses = med_doses*str2num(config.dtc);
        lg_doses = lg_doses*str2num(config.dtc);
        
        % choose .dc2 files
        display('Please choose small feature CAD file...');
        [cad_sm,dir] = uigetfile([folder '\*.dc2']);
        fullCad_sm = fullfile(dir,cad_sm);
        cad_sm=cad_sm(1:end-4);
        display('Please choose med feature CAD file...');
        [cad_med,dir] = uigetfile([folder '\*.dc2']);
        fullCad_med = fullfile(dir,cad_med);
        cad_med=cad_med(1:end-4);
        display('Please choose lg feature CAD file...');
        [cad_lg,dir] = uigetfile([folder '\*.dc2']);
        fullCad_lg = fullfile(dir,cad_lg);
        cad_lg=cad_lg(1:end-4);
        
        %find layers in use
        cad_sm_t = fileread(fullCad_sm);
        cad_med_t = fileread(fullCad_med);
        cad_lg_t = fileread(fullCad_lg);
        
        scad = strrep(cad_sm_t,' ',''); % remove spaces
        ind = regexp(scad,'DoNotUse'); %find index... layers are right after
        scad = scad(ind:ind+1000); %shorten
        scad(isspace(scad))='x'; %replace blanks with 'x'
        indstart = 9;% starting layers index
        indend = min(regexp(scad,'x212'))-1; %ending layers index
        slstr = scad(indstart:indend); %string of layers used separated with x's
        ind_list = regexp(slstr,'xx'); %list of x locations
        ind_list = ind_list(2:end); % skip layer 0
        slayers = {};
        for i = 1:length(ind_list)
            if i<length(ind_list)
                slayers{length(slayers)+1} = slstr(ind_list(i)+2:ind_list(i+1)-1);
            else
                slayers{length(slayers)+1} = slstr(ind_list(end)+2:end-1);
            end
        end
        
        mcad = strrep(cad_med_t,' ',''); % remove spaces
        ind = regexp(mcad,'DoNotUse'); %find index... layers are right after
        mcad = mcad(ind:ind+1000); %shorten
        mcad(isspace(mcad))='x'; %replace blanks with 'x'
        indstart = 9;% starting layers index
        indend = min(regexp(mcad,'x212'))-1; %ending layers index
        mlstr = mcad(indstart:indend); %string of layers used separated with x's
        ind_list = regexp(mlstr,'xx'); %list of x locations
        ind_list = ind_list(2:end); % skip layer 0
        mlayers = {};
        for i = 1:length(ind_list)
            if i<length(ind_list)
                mlayers{length(mlayers)+1} = mlstr(ind_list(i)+2:ind_list(i+1)-1);
            else
                mlayers{length(mlayers)+1} = mlstr(ind_list(end)+2:end-1);
            end
        end
        
        lcad = strrep(cad_lg_t,' ',''); % remove spaces
        ind = regexp(lcad,'DoNotUse'); %find index... layers are right after
        lcad = lcad(ind:ind+1000); %shorten
        lcad(isspace(lcad))='x'; %replace blanks with 'x'
        indstart = 9;% starting layers index
        indend = min(regexp(lcad,'x212'))-1; %ending layers index
        llstr = lcad(indstart:indend); %string of layers used separated with x's
        ind_list = regexp(llstr,'xx'); %list of x locations
        ind_list = ind_list(2:end); % skip layer 0
        llayers = {};
        for i = 1:length(ind_list)
            if i<length(ind_list)
                llayers{length(llayers)+1} = llstr(ind_list(i)+2:ind_list(i+1)-1);
            else
                llayers{length(llayers)+1} = llstr(ind_list(end)+2:end-1);
            end
        end
        
        slayers;
        mlayers;
        llayers;
        
        switch config.sm_aperture
            case 30
                sm_aperture_current = '445.0';
                sm_aperture = '1';
                
            case 7.5
                sm_aperture_current = '17.0';
                sm_aperture = '2';
                
            case 10
                sm_aperture_current = '38.0';
                sm_aperture = '3';
                
            case 40
                sm_aperture_current = '600';
                sm_aperture = '4';
                
            case 60
                sm_aperture_current = '1000';
                sm_aperture = '5';
                
            case 120
                sm_aperture_current = '6000';
                sm_aperture = '6';
                
        end
        
        switch config.lg_aperture
            case 30
                lg_aperture_current = '445.0';
                lg_aperture = '1';
            case 7.5
                lg_aperture_current = '17.0';
                lg_aperture = '2';
            case 10
                lg_aperture_current = '38.0';
                lg_aperture = '3';
            case 40
                lg_aperture_current = '600';
                lg_aperture = '4';
            case 60
                lg_aperture_current = '1000';
                lg_aperture = '5';
            case 120
                lg_aperture_current = '6000';
                lg_aperture = '6';
        end
        
        f = input('Please enter run file filename without a file extension (example: DD_L2_SiGe).' ,'s');
        RunFile_Name = strcat(f,'.RF6');
        Path1 = ['C:\NPGS\Projects\RunFilesFromMATLAB\', RunFile_Name];
        Path2 = [dir, RunFile_Name];
        
        %This ensures we always have an unedited file that can take inputs
        savdir = 'C:\NPGS\Projects\RunFilesFromMATLAB\TemplateArchive';
        copyfile(fulltempfile,savdir);
        copyfile(['C:\NPGS\Projects\RunFilesFromMATLAB\Templates\' templateID '.RF6'], Path1);
        
        %read template and replace proper fields
        f = fileread(Path1);
        
        f = strrep(f,'sm_aperture_current',sm_aperture_current);
        f = strrep(f,'lg_aperture_current',lg_aperture_current);
        f = strrep(f,'cad_sm',cad_sm);
        f = strrep(f,'cad_med',cad_med);
        f = strrep(f,'cad_lg',cad_lg);
        f = strrep(f,'lg_aperture',lg_aperture);
        f = strrep(f,'sm_aperture',sm_aperture);
        f = strrep(f,'al_mag_sm',config.al_mag_sm);
        f = strrep(f,'al_mag_med',config.al_mag_med);
        f = strrep(f,'al_mag_lg',config.al_mag_lg);
        f = strrep(f,'write_mag_lg',config.write_mag_lg);
        f = strrep(f,'write_mag_sm',config.write_mag_sm);
        f = strrep(f,'init_move_x',config.init_move_x);
        f = strrep(f,'init_move_y',config.init_move_y);
        f = strrep(f,'final_move_x',config.final_move_x);
        f = strrep(f,'final_move_y',config.final_move_y);
        
        %colortab from urpec
        ctab={[1 0 0] [0 1 0] [0 0 1] [1 1 0] [1 0 1] [0 1 1] [1 0 0] [0 1 0] [0 0 1] [1 1 0] [1 0 1] [0 1 1] [1 0 0] [0 1 0] [0 0 1] [1 1 0] [1 0 1] [0 1 1]  };
        colorstrings = {};
        for i=1:length(ctab)
            ctabmat = 255.*ctab{i};
            colorstrings{i} = {[num2str(ctabmat(1)) ' ' num2str(ctabmat(2)) ' ' num2str(ctabmat(3))]};
            colorstrings{i} = strrep(colorstrings{i},'0','000');
        end
       
        % generate pattern writing text
        %small
        slogic={}; % logical cell array if layer name exists
        for i=1:length(sm_doses)
            if any(strcmp(slayers,num2str(i)))
                a = 1;
            else
                a = 0;
            end
            slogic{i} = a;
        end
        sdose = [];
        scol = {};
        for i=1:length(slogic)
            if slogic{i}
                sdose(end+1) = sm_doses(i);
                scol{end+1} = colorstrings{i};
            end
        end
        tot_str_s = '';
        nextnum = 2; %layer numbering starts at 2 and goes up with patterns created with urpec
        for i=1:length(slayers)
            strline1 = ['lev_' slayers{i} ' ' num2str(nextnum) ' w    0,0    29106    ' config.write_mag_sm '    42.2974    42.2974    ' sm_aperture '     ' sm_aperture_current];
            strline2 = ['col -001 ' char(scol{i}) ' 10.5239 ' num2str(sdose(i)) ' 0'];
            if i==1
            sm_str = sprintf('lev_%s %s w    0,0    29106    %s    42.2974    42.2974    %s     %s\ncol -001 %s 10.5239 %s 0',...
                slayers{i}, num2str(nextnum), config.write_mag_sm, sm_aperture, sm_aperture_current, char(scol{i}), num2str(sdose(i)));
            else
                %sm_str = sprintf('%s\nlev_%s %s w    0,0    29106    %s    42.2974    42.2974    %s     %s\ncol -001 %s 10.5239 %s 0',...
                %sm_str, slayers{i}, num2str(nextnum), config.write_mag_sm, sm_aperture, sm_aperture_current, char(scol{i}), num2str(sdose(i)));
            end
            nextnum = nextnum + 1;
            if i==1
                tot_str_s = strline1;
            else
                %tot_str_s = [tot_str_s newline strline1];
                tot_str_s=sprintf('%s\r\n%s',tot_str_s,strline1);
            end
            %tot_str_s = [tot_str_s newline strline2];
            tot_str_s=sprintf('%s\r\n%s',tot_str_s,strline2);
        end
        %tot_str_s = sm_str;
        
        %med
        mlogic={}; % logical cell array if layer name exists
        for i=1:length(med_doses)
            if any(strcmp(mlayers,num2str(i)))
                a = 1;
            else
                a = 0;
            end
            mlogic{i} = a;
        end
        mdose = [];
        mcol = {};
        for i=1:length(mlogic)
            if mlogic{i}
                mdose(end+1) = med_doses(i);
                mcol{end+1} = colorstrings{i};
            end
        end
        tot_str_m = '';
        nextnum = 2; %layer numbering starts at 2 and goes up with patterns created with urpec
        for i=1:length(mlayers)
            strline1 = ['lev_' mlayers{i} ' ' num2str(nextnum) ' w    0,0    29106    ' config.write_mag_sm '    42.2974    42.2974    ' sm_aperture '     ' sm_aperture_current];
            strline2 = ['col -001 ' char(mcol{i}) ' 10.5239 ' num2str(mdose(i)) ' 0'];
            nextnum = nextnum + 1;
            if i==1
                tot_str_m = strline1;
            else
                %tot_str_m = [tot_str_m newline strline1];
                tot_str_m=sprintf('%s\r\n%s',tot_str_m,strline1);
            end
            %tot_str_m = [tot_str_m newline strline2];
            tot_str_m=sprintf('%s\r\n%s',tot_str_m,strline2);
        end
        
        %lg
        llogic={}; % logical cell array if layer name exists
        for i=1:length(lg_doses)
            if any(strcmp(llayers,num2str(i)))
                a = 1;
            else
                a = 0;
            end
            llogic{i} = a;
        end
        ldose = [];
        lcol ={};
        for i=1:length(llogic)
            if llogic{i}
                ldose(end+1) = lg_doses(i);
                lcol{end+1} = colorstrings{i};
            end
        end
        tot_str_l = '';
        nextnum = 2; %layer numbering starts at 2 and goes up with patterns created with urpec
        for i=1:length(llayers)
            strline1 = ['lev_' llayers{i} ' ' num2str(nextnum) ' w    0,0    29106    ' config.write_mag_lg '    42.2974    42.2974    ' lg_aperture '     ' lg_aperture_current];
            strline2 = ['col -001 ' char(lcol{i}) ' 10.5239 ' num2str(ldose(i)) ' 0'];
            nextnum = nextnum + 1;
            if i==1
                tot_str_l = strline1;
            else
                %tot_str_l = [tot_str_l newline strline1];
                tot_str_l=sprintf('%s\r\n%s',tot_str_l,strline1);
            end
            %tot_str_l = [tot_str_l newline strline2];
            tot_str_l=sprintf('%s\r\n%s',tot_str_l,strline2);
        end
        
        %replace text
        f = strrep(f,'smallwriting',tot_str_s);
        f = strrep(f,'mediumwriting',tot_str_m);
        f = strrep(f,'largewriting',tot_str_l);
        
        fid = fopen(Path1,'w');
        fprintf(fid,f);
        fclose(fid);
        
        %place file in project directory
        copyfile(Path1, Path2);
        
        %Code to convert mixed terminator file to CRLF DOS formatting
        %get unix path
        %ind = [regexp(dir,'\')];
        %projFolder = dir(ind(end-1)+1:end-1);
        %unixpath = ['/mnt/c/NPGS/Projects/' projFolder '/' RunFile_Name];
        
        %convert to fix for dos formatting
        %success = system(['bash -c ''unix2dos ' unixpath '''']);
        %if success == 0
        %    display('Conversion from unix to dos successful.');
        %else
        %    display('Conversion failed from unix to dos... Run file may not be editable in NPGS Run File Editor');
        %end
        %copy corrected file back to run files from matlab dir
        copyfile(Path2,Path1);
        
        display(['Run file ' RunFile_Name ' created in ' Path2 ' with a backup created in ' Path1])
end

end

% Apply a default.
function s=def(s,f,v)
if(~isfield(s,f))
    s=setfield(s,f,v);
end
end

% % testing
% config= struct;
% config.dtc = '400'
% config.write_mag_sm = '1500';
% config.sm_aperture = 7.5;
%config.sm_aperture_current = '17';
% config.write_mag_sm = '1500';
% cofig.write_mag_lg = '600';
% config.al_mag_sm = '1500';
% config.al_mag_med = '800';
% config.al_mag_lg = '235';
% config.lg_aperture = 30;
% config.lg_aperture_current = '445';
% config.init_move_x = '105';
% config.init_move_y = '-12';
% config.final_move_x = '-747';
% config.final_move_y = '-123';


