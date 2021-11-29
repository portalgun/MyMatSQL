classdef MMS_Table < handle & MMS_cmn
properties
    name
    bInUse
    flds

    Schema
    schemasStruct
end
properties(Hidden)
    table_name
end
methods
    function obj=MMS_Table(mms,varargin)
        obj.mms=mms;
        p=MMS_Table.get_parseOpts;
        obj=Args.parseIgnore(obj,p,varargin{:});
        obj.name=obj.table_name;
    end
    function use(obj)
        obj.bInUse=true;
    end
    function unuse(obj)
        obj.bInuse=false;
    end
    function out=exist(obj)
        if nargin < 2 && ~isempty(obj.name)
            name=obj.name;
        end
        dbname=obj.dbname;
        cmd=sprintf('SELECT *\nFROM information_schema.tables\nWHERE table_schema = ''%s''AND table_name = ''%s''\nLIMIT 1;',dbname,name);
        obj.fetch(cmd);
        out=~isempty(obj.out);
    end
    function obj=create(obj,name,schema)
        if nargin < 2
            name=obj.name;
        end
        if obj.exist(name)
            error(sprintf('Table ''%s'' already exists',name));
        end
        obj.exec(schema.STR);
    end
    function obj=drop(obj)
        if nargin < 2
            tblname=obj.name;
        end
        % TODO
    end
%% FILEDS
    function getFields(obj)
        obj.check();
        cmd=sprintf('SELECT COLUMN_NAME, DATA_TYPE\nFROM INFORMATION_SCHEMA.COLUMNS\nWHERE TABLE_SCHEMA=''%s''\nAND TABLE_NAME=''%s''',obj.dbname,obj.name); %
        obj.fetch(cmd);
        obj.flds=[obj.out.COLUMN_NAME obj.out.DATA_TYPE];
    end
    function obj=newField(obj,fldName,type)
        obj.check();
        if nargin < 3
            type='VARCHAR(255)';
        end
        cmd=sprintf('ALTER TABLE %s ADD COLUMN %s %s', obj.tblname, fldName, type);
    end
    function [ind,mFlds]=hasFields(obj,flds)
        if isempty(obj.flds)
            obj.getFlds();
        end
        ind=~ismember(flds,obj.flds(:,1));
        if nargout > 1
            mFlds=[flds{ind}];
        end
    end
end
methods(Static)
    function p=get_parseOpts()
        p={...
           'table_name',[],'ischar_e' ...
          };

    end
end
end
