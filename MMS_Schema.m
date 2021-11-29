classdef MMS_Schema < handle
properties
    name
    STR
    bPRIMARY
    bUNQIND
    Opts
end
methods
    function obj=MMS_Schema(name,s)
        obj.name=name;
        [obj.STR, obj.Opts]=MMS_Schema.parse(name,s);
    end
end
methods(Static)
    function [STR, S]=parse(name,s)
        flds=fieldnames(s);
        [~,S]=MMS_Schema.parse_field('','');
        STR=cell(length(flds),1);
        %O=cell(length(flds),1);
        %S=cell(length(flds),1);
        for i = 1:length(flds)
            [STR{i},S(i)]=MMS_Schema.parse_field(flds{i},s{flds{i}});
        end
        STR=strjoin(STR,newline);

        primary=flds([S.bPRIMARY]);
        pstr='';
        if ~isempty(primary)
            p=strjoin(primary,', ');
            pstr=sprintf('PRIMARY KEY (%s) ', p);
        end
        if ~isempty(pstr)
            pstr=[newline pstr(1:end-1)];
        end

        inds=[S.UNQIND];
        bins=unique(inds);
        cstr='';
        for i = 1:length(bins)
            if bins(i)==0
                continue
            end
            ustr=strjoin(flds(inds==bins(i)),', ');
            uustr=strrep(ustr,', ','_');
            cstr=[cstr sprintf('CONSTRAINT %s_unique UNIQUE (%s) ',uustr,ustr)];
        end
        if ~isempty(cstr)
            cstr=[newline cstr(1:end-1)];
        end
        if isempty(cstr) && isempty(pstr)
            STR(1:end-1);
        end
        if ~isempty(cstr) && ~isempty(pstr)
            cstr=[cstr ','];
        end
        STR=['CREATE TABLE ' name ' (' newline STR cstr pstr newline ');'];
    end
end
methods(Static,Hidden)
    function [str,S]=parse_field(name,props)
        S=struct();
        S.name=name;
        S.type='';
        S.default='';
        S.bUnique=false;
        S.bNotNull=false;
        S.bAutoInc=false;
        S.bAutoInc=false;

        S.bPRIMARY=false;
        S.UNQIND=0;
        if isempty(props)
            str='';
            return
        end
        flds=fieldnames(props);
        for i = 1:length(flds)
            prop=flds{i};
            val=[];
            if startsWith(prop,'FLD_')
                prop=props.(prop);
            elseif isnumeric(props{prop}) && ~isempty(props{prop})
                val=props{prop};
            end


            num=Str.RE.match(prop,'\([0-9]+\)');
            prop=regexprep(prop,'[^a-zA-Z]','');
            bType=false;
            switch prop;
                case{'primary','PRIMARY'}
                    S.bPRIMARY=true;
                case{'unique','UNIQUE'}
                    if isempty(val)
                        S.bUnique=true;
                    else
                        S.UNQIND=val;
                    end
                case {'nn','NN','NOT NULL','notnull','NOTNULL','NOT_NULL','not_null'}
                    S.bNotNull=true;
                case {'inc','INC','AUTO','auto','auto inc','AUTO INC','auto_inc','AUTO_INC','auto_increment','AUTO_INCREMENT','auto increment','AUTO INCREMENT'}
                    S.bAutoInc=true;
                    bType=true;;
                case {'char','CHAR'}
                    S.type=['CHAR' num];
                    bType=true;
                case {'int','INT','integer','INTEGER'}
                    S.type='INTEGER';
                    bType=true;
                case {'varchar','VARCHAR'}
                    S.type=['VARCHAR' num];
                    bType=true;
                case {'int','INT'}
                    S.type=['VARCHAR' num];
                    bType=true;
                case {'edited','EDITED'}
                    S.type='EDITED';
                    bType=true;
                case {'created','CREATED'}
                    S.type='CREATED';
                    bType=true;
                case {'time','TIME'}
                    S.type='TIME';
                    bType=true;
                case {'timestamp','TIMESTAMP'}
                    S.type='TIMESTAMP';
                    bType=true;
                case {'time','TIME'}
                    S.type='TIME';
                    bType=true;
                case {'bool','BOOL'}
                    S.type='BOOL';
                    bType=true;
                otherwise
                    error(['unrecognized property ''' prop '''for ''' S.name '''']);
            end
            if bType && ~isempty(val)
                if isnumeric(val)
                    val=num2str(val);
                end
                S.default=val;
            end
        end
        if isempty(S.type)
            error(['No Type Defined for ' S.name]);
        end
        str=MMS_Schema.create_fld_str(S);
    end
    function str=create_fld_str(S)
        if strcmp(S.type,'EDITED')
            type='TIMESTAMP';
            ap=' DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP';
        elseif strcmp(S.type,'CREATED')
            type='DATETIME';
            ap=' DEFAULT CURRENT_TIMESTAMP';
        else
            type=S.type;
            ap='';
        end
        if S.bNotNull
            nn=' NOT NULL';
        else
            nn='';
        end
        if S.bAutoInc
            ai=' AUTO_INCREMENT';
        else
            ai='';
        end
        if S.bUnique
            un=' UNIQUE';
        else
            un='';
        end
        if ~isempty(S.default)
            df=[' DEFAULT ' S.default];
        else
            df='';
        end
        str=[ S.name ' ' type nn df ai un ap ','];

    end
end
end
