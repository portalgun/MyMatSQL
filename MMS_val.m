classdef MMSval < handle
% XXX MAYBE DON"T WORK ON THIS
properties
    int={'TINYINT','SMALLINT','MEDIUMINT','INT','BIGINT'};
    % (M) INT SIGNED UNSIGNED ZEROFILL
    dec={'DECIMAL','FLOAT','DOUBLE'};
    % (-,D)
    numeric={'BIT',...
             'TINYINT','SMALLINT','MEDIUMINT','INT','BIGINT',...
             'DECIMAL','FLOAT','DOUBLE'....
            }

    bit_lim=64
    tinyint_lim=255
    smallint_lim=32727
    mediumint_lim=838807
    int_lim=2147483647
    bigint_lim=1e64
    decimal_lim=1e64
    flaot_lim=e38
    double_lim=e308


    % (M)
end
methods

    function out=parse(type,val)
    end

end
end
