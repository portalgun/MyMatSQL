classdef mysql < handle
properties
    server
    port
    user
    password

    bConnected=0
    bInUse=0

    storage_engine
    jpath
    out

    dbname
    table_name

    flds
    dbflds
    vals

    conn
    curs
end
methods
    function obj=db_connect(obj)
        obj.db_add_path();
        if obj.bConnected==0
            obj.conn = database( obj.dbname ,obj.user, obj.password , 'Vendor','MySQL', 'Server',obj.server, 'PortNumber',obj.port);
        end
        disp(obj.conn.message);
        if isempty(obj.conn.message)
            bConnected=1;
        end
    end
    function obj=db_add_path(obj)
        jpath=javaclasspath('-dynamic');
        warning('off','MATLAB:javaclasspath:invalidFile');
        warning('off','MATLAB:Java:DuplicateClass');
        if iscell(obj.jpath)
            for i = 1:length(obj.jpath)
                p=obj.jpath{i};
                if ~contains(p,jpath)
                    javaaddpath(p); % XXX
                end
            end
        else
            if ~contains(obj.jpath,jpath)
                javaaddpath(obj.jpath);
            end
        end
        warning('on','MATLAB:javaclasspath:invalidFile');
        warning('on','MATLAB:Java:DuplicateClass');
    end
    function obj=db_use(obj)
        cmd=['USE ' obj.dbname];
        obj.db_exec(cmd);
        % XXX
        obj.bInUse=1;
    end
    function obj=db_select_all(obj)
        cmd=['SELECT * FROM ' obj.table_name]
        obj.out=select(obj.conn,cmd);
    end
    function obj=db_exec(obj,cmd)
        if isempty(obj.dbname)
            error('Database unspecified')
        end

        try
            obj.curs = execute(obj.conn,cmd);
        catch
            obj.curs = exec(obj.conn,cmd);
        end
        disp(obj.curs.Message);
    end
    function db_close(obj)
        close(obj.conn);
    end
    function obj=db_ls(obj)
        cmd= 'SHOW DATABASES;';
        %obj.db_exec(cmd);
        fetch(obj.conn,cmd);
    end
    function obj=db_ls_tables(obj)
        cmd= 'SHOW TABLES;';
        %obj.db_exec(cmd);
        fetch(obj.conn,cmd);
    end
    function obj=db_get_fields(obj)
        if ~obj.bConnected
            obj.db_connect();
        end
        cmd=['SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA=''' obj.dbname ''' AND TABLE_NAME=''' obj.table_name ''''];
        obj.out=select(obj.conn,cmd);
        obj.dbflds=obj.out.COLUMN_NAME;
    end
    function obj=db_insert_new_column(obj,fldName)
        if ~obj.bConnected
            obj.db_connect();
        end
        cmd=['ALTER TABLE ' obj.table_name ' ADD COLUMN ' fldName ' VARCHAR(255) ;']
    end
    function [missing,vals]=db_check_fields_exist(obj)
        if isempty(obj.dbflds)
            obj.db_get_fields();
        end
        ind=~ismember(obj.flds,obj.dbflds);
        missing=[obj.flds{ind}];
        vals=[obj.vals{ind}];
    end
    function obj=db_prompt_append_missing(obj)
        [missing,vals]=obj.db_check_fields_exist();
        if isempty(missing)
            return
        end
        display('Missing fields in database:')
        for i = 1:length(missing)
            display(['    ' missing{i}]);
        end
        negat=0;
        for i = 1:length(missing)
            out=basicYN(['Append ' missing{i} '?']);
            if out
                obj.db_insert_new_column(missing{i});
            else
                negat=1;
            end
        end
    end
    function error=db_check_row_exists(obj)
        BEGIN=['SELECT * FROM ' obj.table_name ' WHERE '];
        MIDDLE=obj.get_middle_select();
        END = ';';
        cmd=[BEGIN MIDDLE END];
        obj.out=select(obj.conn,cmd);
        if isempty(obj.out)
            error=1;
        else
            error=0;
        end
    end
end
end
