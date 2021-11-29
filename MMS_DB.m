classdef MMS_DB < handle & MMS_cmn
properties
    server
    port
    user

    name
    inUse=''
    bInUse
    bConnected=false

    conn
end
properties(Hidden)
    password

    jpath
end
methods
    function obj=MMS_DB(mms,varargin);
        obj.mms=mms;
        p=MMS_DB.get_parseOpts;
        obj=Args.parseIgnore(obj,p,varargin{:});

    end
    function connect(obj)
        % TODO ADD SETTING
        %obj.db_add_path();
        if ~obj.bConnected
            obj.conn = database( obj.name ,obj.user, obj.password , 'Vendor','MySQL', 'Server',obj.server, 'PortNumber',obj.port);
        end
        if isempty(obj.conn.Message)
            obj.bConnected=true;
        else
            error(obj.conn.message);
        end
    end
    function obj=close(obj)
        close(obj.conn);
    end
    function obj=use(obj,name)
        if nargin < 2 && ~isempty(obj.name)
            name=obj.name;
        end
        cmd=['USE ' name ';'];
        obj.exec(cmd);
        % ERRORS IF UNSUCCESSFUL

        obj.name=name;
        obj.bInUse=true;
    end
    function obj=unuse(obj)
        obj.inUse='';
        obj.bInUse=false;
    end
    function ls(obj)
        [~,tbl]=obj.getNames();
        disp(obj.out);
    end
    function [out,tbl]=getNames(obj)
        cmd= 'SHOW TABLES;';
        tbl=fetch(obj.conn,cmd);
        out=tbl.TABLE_NAME;
    end
    function obj=db_add_path(obj)
        obj.jpath=javaclasspath('-dynamic');
        if isempty(obj.jpath)
            mysqlConnectorPath();
        end
    end
end
methods(Static)
    function p=get_parseOpts;
        p={...
           'server', '', 'ischar_e' ...
           ;'port', 3306, 'isint_e' ...
           ;'user', '', 'ischar_e' ...
           ;'password', '', 'ischar_e' ...
           ;'dbname','','ischar_e' ...
          };

    end

end
end
