% CI entry point: MATLAB code analyzer errors and basic configuration.
root = fileparts(fileparts(mfilename('fullpath')));
sourceFolder = fullfile(root, 'code');
assert(isfolder(sourceFolder), 'MATLAB source directory not found.');

report = codeIssues(sourceFolder, CodeAnalyzerConfiguration="factory");
T = report.Issues;
isFatal = strcmpi(string(T.Severity), "error");

fprintf('Analyzed %d MATLAB files. Code Analyzer: %d error(s), %d other issue(s).\n', ...
    numel(report.Files), nnz(isFatal), height(T) - nnz(isFatal));
if any(isFatal)
    disp(T(isFatal, {'Location','CheckID','LineStart','Description'}));
    error('MATLAB static analysis found %d error-level issue(s).', nnz(isFatal));
end

addpath(sourceFolder);
cfg = config();
assert(numel(cfg.regions) == 4, 'Expected four configured lunar regions.');
fprintf('MATLAB static analysis and config smoke test passed.\n');
