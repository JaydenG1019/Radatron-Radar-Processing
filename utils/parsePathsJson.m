function pathsOut = parsePathsJson(jsonFile,dayIdx)
    fid = fopen(jsonFile);
    raw = fread(fid,inf);
    str = char(raw'); 
    if nargin>1
        str = strrep(str,'dayIdx',['day',num2str(dateIdx)]);
    end
    fclose(fid);

    pathsOut = jsondecode(str);
    
    resultsPath_fields = fieldnames(pathsOut.results);
    numFields = numel(resultsPath_fields);
    
    for i = 1:numFields
        fieldName = char(resultsPath_fields(i));
        pathsOut.results.(fieldName) = fullfile(pathsOut.resultsRoot, pathsOut.results.(fieldName));
    end
end