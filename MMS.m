classdef MMS < handle & MMS_cmn
properties
    DB
    Tables
    Entry
    i_tableNames
    tableNames
    curTableName
    curTable

    Schemas
    schemaNames

    schema_fname
    connect_fname

end
methods
    function obj=MMS(varargin);
        P=MMS.get_parseOpts();
        obj=Args.parseIgnore(obj,P,varargin{:});
        obj.check_all_args(varargin{:});

        %% DB
        if ~isempty(obj.connect_fname)
            dbOpts=Cfg.read(obj.connect_fname);
            dbOpts=Args.toPairs(dbOpts);
            obj.check_all_args(dbOpts{:});
            dbOpts=[varargin dbOpts];
        else
            dbOpts=varargin ;
        end
        obj.DB=MMS_DB(obj,dbOpts{:});

        %% Schema
        if ~isempty(obj.schema_fname)
            Schemas=Cfg.read(obj.schema_fname);
            obj.createSchemas(Schemas);
        end
        obj.Entry=MMS_Entry(obj);

        % SELF REF FOR COMMON
        obj.mms=obj;
    end
%% UTIL
    function obj=connect(obj)
        [~,code]=obj.check();
        if code==1
            obj.DB.connect();
        end
        if code<=2
            obj.DB.use();
        end
    end
    function useTable(obj,name);
        obj.Tables{name}.use();
        if ~isempty(obj.curTableName)
            obj.Tables{obj.curTableName}.unuse;
        end
        obj.curTableName=name;
        obj.curTable=obj.Tables{name};
        obj.curTable.use();
    end
%% MAIN
    function obj=create(obj);
        [msg,code]=obj.check();
        if code < 3
            error(msg);
        end
        vals=cell(numel(obj.schemaNames),1);
        keys=obj.schemaNames;
        for i = 1:length(keys);
            name=keys{i};
            vals{i}=MMS_Table(obj,'table_name',name);

            if ~vals{i}.exist;
                vals{i}.create(name,obj.Schemas{name});
            end
        end
        obj.Tables=dict(keys,vals);
        obj.i_tableNames=keys;
    end
    function obj=initialize(obj)
        keys=obj.DB.getNames;
        obj.tableNames=keys;
        vals=cell(numel(keys),1);
        for i = 1:length(keys)
            if ismember(keys{i},obj.i_tableNames)
                vals{i}=obj.Tables{keys{i}};
            else
                vals{i}=MMS_Table(obj,'table_name',name);
            end
            vals{i}.getFields;
        end
        obj.Tables=dict(keys,vals);
        obj.i_tableNames=keys;
    end
end
methods(Access=private)
    function obj=createSchemas(obj,Schemas)
        names=Schemas.keys;
        vals=cell(size(names));
        for i = 1:length(names)
            vals{i}=MMS_Schema(names{i},Schemas{names{i}});
        end
        obj.Schemas=dict(names,vals);
        obj.schemaNames=names;
    end
    function obj=check_all_args(obj,varargin)
        P=[MMS_DB.get_parseOpts; ...
           MMS_Table.get_parseOpts; ...
           %MMS_Schema.getParseOpts; ...
          ];
        UM=Args.getUnmatched(P,varargin{:});
        if ~isempty(UM)
            Args.throwUnmatchedError('MyMatSql',UM);
        end
    end
end
methods(Static)
    function P=get_parseOpts();
        P={...
              'schema_fname',[],'ischar_e'; ...
              'connect_fname',[],'ischar_e'; ...
          };

    end
    function obj=test();
        obj=MMS('schema_fname','/home/dambam/Documents/MATLAB/.px/prj/MyMatSql/imap_mysql.cfg', ...
                'connect_fname','/home/dambam/Documents/MATLAB/.px/prj/MyMatSql/dbconfig.cfg');
        obj.connect();
        obj.create();
        %obj.initialize();

    end

end
end
