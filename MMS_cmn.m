classdef MMS_cmn < handle
properties
    tablename
    dbname
    curs
    con
    out
end
properties(Access=protected)
    mms
    last_cmd
end
methods
    function obj=exec(obj,cmd,bQuiet)
        if isa(obj,'MMS')
            error('MMS should not execute functions');
        end
        obj.last_cmd=cmd;
        obj.mms.last_cmd=cmd;
        if nargin < 3
            bQuiet=false;
        end
        obj.check();

        try
            obj.curs = execute(obj.con,cmd);
        catch
            obj.curs = exec(obj.con,cmd);
        end
        obj.mms.curs=obj.curs;
        if isnumeric(obj.curs.Cursor) && obj.curs.Cursor==0
            error([newline obj.curs.SQLQuery newline newline obj.curs.Message]);
        end
        if ~bQuiet
            disp(obj.curs.Message);
        end
    end
    function obj=fetch(obj,cmd)
        if isa(obj,'MMS')
            error('MMS should not fetch');
        end
        obj.last_cmd=cmd;
        obj.mms.last_cmd=cmd;
        try
            obj.out=fetch(obj.con,cmd);
        catch ME
            msg=[cmd newline newline ME.message];
            ME=MException(ME.identifier,msg);
            throw(ME);
        end
    end
    function printQuery(obj)
        disp(obj.curs.SQLQuery);
    end
    function [msg,code]=check(obj,type)
        msg=[];
        code=inf;
        if ~obj.mms.DB.bConnected
            msg='Not Connected to Server';
            code=1;
        elseif ~obj.mms.DB.inUse
            msg='No DB selected';
            code=2;
        elseif isempty(obj.mms.curTable)
            msg='No Table selected';
            code=4;
        end
        if nargout < 1 && ~isempty(msg)
            error(msg);
        end
        if nargin < 2
            return
        elseif isa(obj,'MSS_Entry')
            obj.check_;
        end

    end
    function out=get.con(obj)
        if isa(obj,'MMS_DB')
            out=obj.conn;
        elseif isa(obj,'MMS')
            out=obj.DB.conn;
        else
            out=obj.mms.DB.conn;
        end
    end
    function set.dbname(obj,name)
        if isa(obj,'MMS_DB')
            obj.name=name;
        else
            obj.mms.DB.name=name;
        end
    end
    function name=get.dbname(obj)
        bDB=isa(obj,'MMS_DB');
        if bDB && obj.InUse
            name=obj.name;
        elseif ~bDB && obj.mms.DB.bInUse
            name=obj.mms.DB.name;
        else
            name='';
        end
    end
    function name=get.tablename(obj)
        if isa(obj,'MMS');
            name=obj.curTable;
        else
            name=obj.mms.curTable;
        end
    end
    function tbl=table(obj)
        if ~isemtpy(obj.mms.curTable)
            obj.Table{obj.mms.curTable};
        else
            error('No table in use');
        end
    end
end
end
