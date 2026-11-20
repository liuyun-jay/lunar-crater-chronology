function ok = lint_all(codeDir, outFile)
%LINT_ALL  Static check of every .m file, with a pass/fail gate for CI.
%
%   ok = lint_all()            checks ./code and prints a summary
%   ok = lint_all('code')      checks the given folder
%   ok = lint_all('code','lint.txt')  also writes an ASCII report
%
%   用法：M 文件越多越应该先跑这个。checkcode 的消息标识是 5 位助记码，其中
%   三类直接说明文件无法被 MATLAB 解析，必须视为失败：
%       BADCH  无效的文本字符（通常是中文/全角字符跑到了代码里）
%       SYNER  语法错误（括号、分隔符、续行不匹配）
%       STRIN  字符串未终止（单引号被换行拆断）
%   其余（NOPRT 缺分号、DEFNU 循环内变量变尺寸、CAXIS 已弃用等）只作为建议，
%   不阻塞合并。这样 CI 抓的是"跑不起来"，而不是代码风格。
%
%   输出：ok 为 true 表示没有致命问题；有致命问题时本函数会 error()，
%   使 MATLAB -batch 以非零状态退出，GitHub Actions 因此变红。

arguments
    codeDir (1,1) string = "code"
    outFile (1,1) string = ""
end

fatalIds = ["BADCH", "SYNER", "STRIN"];

if ~isfolder(codeDir)
    error('lint_all:noFolder', '找不到代码目录：%s', codeDir);
end

files = dir(fullfile(codeDir, '*.m'));
[~, order] = sort(string({files.name}));
files = files(order);

fid = -1;
if strlength(outFile) > 0
    fid = fopen(outFile, 'w', 'n', 'UTF-8');
end

nMsg = 0;
nFatalTotal = 0;
fatalDetail = strings(0, 1);

for k = 1:numel(files)
    name = files(k).name;
    msgs = checkcode(fullfile(codeDir, name), '-id');

    nFatal = 0;
    for m = 1:numel(msgs)
        nMsg = nMsg + 1;
        if isfield(msgs, 'id') && ~isempty(msgs(m).id)
            id = string(msgs(m).id);
        else
            id = "NO_ID";
        end
        isFatal = any(id == fatalIds);
        if isFatal
            nFatal = nFatal + 1;
            % 只记录标识与位置：消息正文随语言变化，日志里保留英文/中文都没意义
            fatalDetail(end + 1, 1) = sprintf('  %s:%d  %s', name, msgs(m).line, id); %#ok<AGROW>
        end
        if fid > 0
            fprintf(fid, '%s|%d|%s\n', name, msgs(m).line, id);
        end
    end

    if nFatal > 0
        fprintf('  [FATAL] %-28s %d 个致命问题\n', name, nFatal);
    end
    nFatalTotal = nFatalTotal + nFatal;
end

if fid > 0
    fclose(fid);
end

fprintf('lint_all: 检查 %d 个文件，%d 条消息，%d 条致命\n', ...
    numel(files), nMsg, nFatalTotal);

ok = (nFatalTotal == 0);
if ~ok
    fprintf('%s\n', fatalDetail);
    error('lint_all:failed', ...
        '%d 个文件无法被 MATLAB 解析，请先修复后再提交。', nFatalTotal);
end
end
