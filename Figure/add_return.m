% Long string with single row is converted to 
% shorter multiple rows.
% Convenient when adding description to Figure.
%
% Input
%  str: 1xN string.
%  str_length: maximum number of rows in output string (default:100).
%
% Output
%  str_new: nxstr_length string.
%
% If length(str)<str_length, this function do nothing and str_new
% is the same as str.

function str_new = add_return(str,str_length)

%% check the input
if nargin == 1
    str_length = 100;
end

%% Initialize str_new
str_new = repmat(' ',str_length,1000);

%% Insert string.
str_new(1:length(str)) = str;

%% Remove unnecessary colums.
for i = size(str_new,2): -1: 1
    if ~strcmp(str_new(:,i) , repmat(' ',str_length,1))
        break
    end
end

str_new = str_new(:,1:i);

    %% Make output
    str_new = str_new';
    