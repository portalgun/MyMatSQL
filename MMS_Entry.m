classdef MMS_Entry < handle & MMS_cmn
properties
    tableName

    flds
    fldNames
    fldTypes
end
methods
    function obj=MMS_Entry(mms)
        obj.mms=mms;
    end
    function out=exists(obj)
        obj.check('select');
        crit=sprintf('hash=%s',obj.hash);
        out=obj.Mysql.hasEntry(crit, obj.tablename);
    end
    function error=hasEntry(obj,crit)
        % XXX ?
        cmd=sprintf('SELECT EXISTS (SELECT * FROM %s WHERE\n%s\n;',tblname,crit);
        crit=parse_crit(cmd,crit);
        sel=obj.fetch(cmd);

        if ~isempty(sel)
            out=1;
        else
            out=0;
        end
    end

%% SELECT
    function get(obj)
        obj.check('select');
        obj.select();
    end
    % XXX
    function obj=db_prompt_append_missing(obj)
        [missing,vals]=obj.hasFlds();
        if isempty(missing)
            return
        end
        display('Missing fields in database:')
        for i = 1:length(missing)
            display(['    ' missing{i}]);
        end
        negat=0;
        for i = 1:length(missing)
            out=Input.yn(['Append ' missing{i} '?']);
            if out
                obj.newColumn(missing{i});
            else
                negat=1;
            end
        end
    end

    function obj=select(obj,fldNames,crit,table_name)
        obj.check();
        if nargin < 4
            table_name=obj.table_name;
            if nargin < 3
                crit=[];
                if nargin < 2
                    fldName=[];
                end
            end
        end
        if isempty(fldName)
            obj.out='';
            return
        end

        if ~iscell(fldName)
            fldName={fldName};
        end
        bExist=false(length(fldNameS),1);
        bExist=obj.hasFlds(fldNames);
        if ~all(bExist)
            flds=strjoin(fldNames(bExist),newline);
            error(['Fields do not exist:' newline flds ]);
        end
        fldNames=strjoin(fldNames,', ');
        cmd=['SELECT ' fldNames ' FROM ' table_name];

        cmd=MyMatSql.parse_crit(cmd, crit);
        cmd=[cmd ';']
        obj.out=select(obj.conn,cmd);
    end
    function obj=selectAll(obj)
        obj.check();
        cmd=['SELECT * FROM ' obj.tblname ';'];
        obj.out=select(obj.con,cmd);
    end
%% NEW
    function new(obj,varargin)
        if isstruct(varargin{1})
            Opts=vararagin{1};
        else
            Opts=struct(varargin{:});
        end
        obj.parse_entry(Opts);
        obj.check('new');
        obj.insert();
    end
%% UPDATE
    function rename(obj,old,new)
        % TODO
        % get primary key
    end
    function update(obj,varargin)
        if isstruct(varargin{1})
            Opts=vararagin{1};
        else
            Opts=struct(varargin{:});
        end
        obj.parse_entry(Opts);
        obj.check('update');
        obj.insert();
        obj.update__();
    end
%% DELETE
    function obj=delete(obj,crit)
        obj.check('select');
        cmd=['DELETE FROM ' tblname '\nWHERE'];
        obj.parse_crit(cmd,crit);
    end
    function check_(type)
        switch type
        case 'new'
            if obj.exists()
                obj.error_exist();
            end
            if ~obj.matches_schema()
                obj.error_not_match_schema();
            end

        case {'update','select'}
            if ~obj.exists()
                obj.error_not_exist();
            end
        end
    end
end
methods(Static)
    function cmd=parse_crit(cmd,crit)
        if ~isempty(crit)
            if iscell(crit)
                % TODO parse crit table
            end
            cmd=[cmd ' WHERE ' crit];
        end
    end
end
methods(Access=private)
    function parse_entry(obj,S)
        flds=fieldnames(S);
        for i = 1:length(flds)
            if ~ismember(flds{i},obj.fldNames)
                obj.error_invalid_field(flds{i});
            end
            type=obj.get_type(obj,fldName);
            if ~MySqlEntry.isValidVal(obj.(flds{i}))
                obj.error_invalid_value(obj.(flds{i}));
            end
        end
    end
    function out=get_type(obj,fldName)
        out=obj.fldTypes(ismember(fldName,obj.fldNames));
    end
    function isValidVal(type,val)
        % TODO LATER
        out=true;
    end
    function insert(obj)
    end
    function update_(obj)
    end
%% ERRORS
    function error_invalid_value(value)
        msg='';
        error(value);
    end
    function error_connection()
        msg='';
        error(msg);
    end
    function error_not_table()
        msg='';
        error(msg);
    end
    function error_not_exist()
        msg='';
        error(msg);
    end
    function error_exist()
        msg='';
        error(msg);
    end
    function error_not_match_schema()
        msg='';
        error(msg);
    end
    function error_invalid_filed(fld)
        msg=fld;
        error(msg);
    end
end
end
