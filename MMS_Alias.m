classdef MySqlAlias < handle & MMS_Entry & MMS_cmn
properties
end
methods
    function MySqlAlias(mysql, db, tableName)
        obj@MySqlEntry(mysql, db, tableName);
    end
end
