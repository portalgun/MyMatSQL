classdef matdata < handle & mysql
properties
    data
    data_short
    cls
    hash

    fname
% TODO ignore params
end
properties(Hidden = true)
    bNumeric
    bIgnore
    dir

    existFile
    existDB
end
methods
    function obj = matdata(cls,data,bIgnore)
        data=obj.cleanup(data);

        if ~exist('cls','var')
            cls=[];
        end
        if ~exist('data','var')
            data=[];
        end
        if ~exist('bIgnore','var')
            bIgnore=[];
        end
        obj.cls=cls;
        obj.data=data;
        obj.bIgnore=bIgnore;

        obj.init();
    end
    function obj =  init(obj)
        obj.get_vars();
        obj.get_fields(obj.data);
        obj.hash=DataHash(obj.data_short);
        obj.db_get_table_name;
        obj.get_fname();
    end
    function data=cleanup(obj,data)
        if ~isstruct(data)
            warning('off','MATLAB:structOnObject');
            data=struct(data);
        end
        if isfield(data,'Out')
            data=rmfield(data,'Out');
        end
        if isfield(data,'Ind')
            data=rmfield(data,'Ind');
        end
        if isfield(data,'packVars')
            data=rmfield(data,'packVars');
        end
        if isfield(data,'patches')
            data=rmfield(data,'patches');
        end
    end
    function obj = get_vars(obj)
        obj.dir='/Volumes/Data_l/.daveDB/data/';
        obj.jpath{1}='/home/dambam/src/mysql-connector-java-5.1.48.jar';
        obj.jpath{2}='/home/dambam/src/mysql-connector-java-5.1.48-bin.jar';
        %obj.server='localhost';
        obj.server='jiggamortz.com';
        obj.storage_engine='INNODB';
        obj.password='hhmR8zkB8v3rRxbuDFPrJ';
        obj.user='matlab';
        obj.dbname='matdata';
        obj.port=3306;
    end
    function obj = get_fname(obj)
        if isempty(obj.cls)
            obj.fname=obj.hash;
        else
            obj.fname=[obj.cls '_'  obj.hash];
        end
    end
%%%%%
    function COL=get_short_col(obj)
        COL=printColumn(obj.data_short);
    end
    function obj=db_append(obj)
        obj.db_connect();
        obj.db_use();

        obj.db_create_table();
        obj.db_prompt_append_missing;
        obj.db_insert();

        obj.db_close();
    end
%%%%%%
    function obj=save_n(obj)
        obj.save_fun(obj.data,'');
    end
    function obj=save_in(obj,data)
        data=obj.cleanup(data);
        obj.save_fun(data,'in');
    end
    function obj = save_out(obj,data)
        data=obj.cleanup(data);
        obj.save_fun(data,'out');
    end
    function obj = save_fun(obj,data,inORout)
        if exist('inORout','var') && ~isempty(inORout)
            inORout=[inORout '_'];
        end
        save([obj.dir inORout obj.fname],'data','-v7.3');
    end
%%%%%%
    function data=load_in(obj)
        data=obj.load_fun('in');
    end
    function data=load_out(obj)
        data=obj.load_fun('out');
    end
    function data=load_fun(obj,inORout)
        obj.db_connect();
        obj.db_use();
        obj.db_select_fname();
        obj.db_close();

        fname=[obj.dir inORout obj.fname];
        load(fname);
    end
%%%%%
    function obj = get_fields(obj,data)
        flds=fieldnames(struct(data));

        data=obj.flatten(data,flds);
        data=obj.rm_large(data);
        data=obj.num2char(data);

        obj.flds=fieldnames(data);
        obj.data_short=data;
        obj.get_vals;

        %starts with b
        %has opts
        %is char
    end
    function data=flatten(obj,data,flds)
        rmInd=zeros(size(flds));
        for i = 1:length(flds)
            fld=flds{i};
            d=data.(fld);

            c=class(d);
            sc=superclasses(d);
            ind=contains(sc,'handle');
            sc(ind)=[];

            if isbuiltin(d) && ~isstruct(d)
                continue
            elseif strcmp(c,'ptb_session')
                rmInd(i)=1;
                continue
            elseif ~isempty(sc)
                data.(fld)=c;
                continue;
            elseif ~isstruct(d)
                try
                    d=struct(d);
                catch
                    continue
                end
            end
            flds2=fieldnames(d);
            for j = 1:length(flds2)
                fld2=flds2{j};
                newfld=[fld '_' fld2];
                data.(newfld)=d.(fld2);
            end
            rmInd(i)=1;
        end
        for i = 1:length(rmInd)
            fld=flds{i};
            if rmInd(i)
                data=rmfield(data,fld);
            end
        end
    end
    function data=rm_large(obj,data)
        n=5;
        flds=fieldnames(data);
        for i = 1:length(flds)
            fld=flds{i};
            if ((isnumeric(data.(fld)) || islogical(data.(fld))) && numel(data.(fld)) > n) || isstruct(data.(fld)) || iscell(data.(fld))
                data=rmfield(data,fld);
            elseif isnumeric(data.(fld)) && (isempty(data.(fld)) || all(isnan(data.(fld))))
                data=rmfield(data,fld);
            elseif strcmp(fld,'bTest') || (~isempty(obj.bIgnore) && contains(fld,obj.bIgnore))
                data=rmfield(data,fld);
            end
        end
    end
    function data=num2char(obj,data)
        flds=fieldnames(data);
        obj.bNumeric=zeros(size(flds));
        for i = 1:length(flds)
            fld=flds{i};
            if isnumeric(data.(fld))
                obj.bNumeric(i)=1;
                data.(fld)=strrep(num2strSane(data.(fld)),',','_');
                b=contains(data.(fld),'_');
                if b
                    obj.bNumeric(i)=0;
                end
                data.(fld)=['''' data.(fld) ''''];
                %data.(fld)=strrep(num2strSane(data.(fld)),',','_');
            else
                data.(fld)=['''' data.(fld) ''''];
            end
        end
    end
    function data=get_vals(obj)
        n=length(obj.flds);
        obj.vals=cell(n,1);
        for i = 1:n
            fld=obj.flds{i};
            obj.vals{i}=obj.data_short.(fld);
        end
    end
%%%%%
%%%%%%
    function obj=db_select_fname(obj)
        error=obj.db_check_row_exists();
        if error==1;
            error('Database entry does not exist - not loading')
        end
        obj.db_select('fname');
        obj.fname=obj.out.fname{1};
    end
    function obj=db_select(obj,fld)
        if ~exist('fld','var') || isempty(fld)
            fld='*';
        end
        obj.db_get_fields();
        if ~ismember(fld,obj.dbflds)
            error(['Field ''' fld ''' does not exist in table'])
        end
        BEGIN=['SELECT ' fld ' FROM ' obj.table_name ' WHERE '];
        MIDDLE=obj.get_middle_select();
        %END = ');';
        END = ';';
        cmd=[BEGIN MIDDLE END];
        obj.out=select(obj.conn,cmd);
    end
    function MIDDLE = get_middle_select(obj)
        obj.db_get_fields();
        MIDDLE='';
        for i = 1:length(obj.flds)
            if ~ismember(obj.flds{i},obj.dbflds)
                continue
            end
            if obj.bNumeric(i)
                fld=['cast(' obj.flds{i} ' as decimal(5,1))'];
            else
                fld=obj.flds{i};
            end
            if i<length(obj.flds)

                MIDDLE=[MIDDLE newline '    ' fld '=' obj.vals{i} ' AND'];
            else
                MIDDLE=[MIDDLE newline '    ' fld '=' obj.vals{i}];
            end
        end
    end
    function obj=db_create_table(obj)
        BEGIN=['CREATE TABLE IF NOT EXISTS ' obj.table_name '(' newline  ...
               '    id INT AUTO_INCREMENT PRIMARY KEY, ' newline ...
               '    hash VARCHAR(255) NOT NULL UNIQUE, '  newline ...
               '    class VARCHAR(255) NOT NULL, ' newline ...
               '    fname VARCHAR(255) NOT NULL, ' newline];
        MIDDLE='';
        for i = 1:length(obj.flds)
            if obj.bNumeric(i)
                MIDDLE=[MIDDLE '    ' obj.flds{i} ' FLOAT,' newline];
            else
                MIDDLE=[MIDDLE '    ' obj.flds{i} ' VARCHAR(255),' newline];
            end
        end

        END=['    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP' newline ...
            ') ENGINE=' obj.storage_engine ';'];
        cmd=[BEGIN MIDDLE END];
        obj.db_exec(cmd);
    end
    function obj=db_insert(obj)
%BEGIN=['INSERT INTO ''' obj.table_name '' '('];
        BEGIN=['INSERT INTO ' obj.table_name ' ('];
        MIDDLE=obj.get_middle_insert();

        END = ['''' obj.hash ''',''' obj.cls ''',''' obj.fname ''');'];
        cmd=[BEGIN MIDDLE END];
        obj.db_exec(cmd);
    end
    function MIDDLE=get_middle_insert(obj)
        MIDDLE1='';
        for i = 1:length(obj.flds)
            MIDDLE1=[MIDDLE1 obj.flds{i} ','];
        end
        MIDDLE1=[MIDDLE1 'hash,class,fname) VALUES ('];

        MIDDLE2='';
        for i = 1:length(obj.flds)
            MIDDLE2=[ MIDDLE2 obj.vals{i} ',' ];
        end
        MIDDLE=[MIDDLE1 MIDDLE2];
    end
    function obj=compare_existing(obj)
        % XXX
    end
    function obj=check_existing_file(obj)
        % XXX
    end
    function obj=db_get_table_name(obj)
        obj.table_name=[obj.cls];
    end
    function obj=db_get_fname(obj)
        % XXX
    end
    function obj=db_add_fld(obj)
        % XXX
    end
    function obj=db_rehash(obj)
        % XXX
    end
end
end
