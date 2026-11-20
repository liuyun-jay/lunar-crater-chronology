% ========================================================================
% 文件名：s11_figstyle.m
% 作用：统一论文图件的字体、配色、网格和白色背景。
% 通俗原理：MATLAB 若跟随系统深色主题，导出图片可能变成黑底。
%       本程序显式设置白底、黑轴、浅灰网格和中文字体，保证所有
%       图片在打印和屏幕上风格一致。
% 输入：无。
% 输出：S 风格结构体，供 make_paper_figures.m 使用。
% ========================================================================
function S = s11_figstyle() % 函数声明：返回论文图件风格
%S11_FIGSTYLE 论文图件统一风格
% 参考用户提供的朱诺案例图件：白底、细黑轴线、浅灰点状网格、柔和配色、
% 底部横向图例、面板字母 (a)(b)、图下说明注记。
%
% 重要：本机 MATLAB 跟随系统深色主题，若不明确定义，导出图片背景会变黑。

% 这里通过 groot 默认属性 + 逐个坐标轴显式设置双重保证白底黑字。

S.fontCN = 'SimSun';                % 正文标签（宋体）
S.fontCNB = 'SimHei';               % 标题（黑体）
S.fs     = 10;                  % 坐标标签字号
S.fsTick = 9.5; % 刻度标签字号
S.fsTitle = 12;                  % 面板标题
S.fsBig = 13.5;                  % 总标题
S.fsNote = 9;                   % 脚注
S.gridCol = [0.85 0.85 0.85]; % 浅灰网格线颜色
S.palette = [0.753 0.314 0.302;       % 砖红
         0.910 0.639 0.239;        % 赭黄
         0.498 0.420 0.353;        %棕
         0.424 0.557 0.678;        % 蓝灰
         0.498 0.659 0.541;        % 灰绿
         0.608 0.541 0.651;        % 紫灰
         0.310 0.427 0.478;        % 深蓝灰
         0.725 0.725 0.725];       % 浅灰

set(groot, 'defaultFigureColor', 'w', ... % 设置默认图窗为白底
       'defaultFigureInvertHardcopy', 'off', ... % 关闭反色打印
       'defaultAxesColor', 'w', ... % 设置坐标区默认白底
       'defaultAxesXColor', 'k', 'defaultAxesYColor', 'k', 'defaultAxesZColor', 'k', ... % 设置坐标轴默认黑色
       'defaultTextColor', 'k', ... % 设置默认文字颜色为黑
       'defaultAxesFontName', S.fontCN, 'defaultTextFontName', S.fontCN, ... % 统一默认字体为宋体
       'defaultLegendTextColor', 'k', 'defaultLegendColor', 'w'); % 图例默认黑字白底
end % 函数结束

% ------------------------------------------------------------------------
function style_ax(ax, S, varargin) % 局部函数：统一坐标轴外观
%STYLE_AX 统一坐标轴外观：白底、无上/右边框、浅灰点状网格
set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'ZColor', 'k', ... % 坐标区白底黑轴
   'Box', 'off', 'TickDir', 'out', 'LineWidth', 0.8, ... % 去掉边框刻度朝外
   'FontName', S.fontCN, 'FontSize', S.fsTick, ... % 统一坐标轴字体字号
   'GridColor', S.gridCol, 'GridAlpha', 1, 'GridLineStyle', ':', ... % 浅灰点状网格线
   'XGrid', 'on', 'YGrid', 'on', 'Layer', 'top'); % 打开网格并置顶显示
if ~isempty(varargin), set(ax, varargin{:}); end % 追加调用者自定义属性
end % 局部函数结束

% ------------------------------------------------------------------------
function panel_title(ax, S, txt) % 局部函数：绘制面板标题
%PANEL_TITLE 面板标题（黑体）
t = title(ax, txt, 'FontName', S.fontCNB, 'FontSize', S.fsTitle, ... % 用黑体绘制面板标题
   'FontWeight', 'normal', 'Color', 'k'); % 标题字重与颜色
end % 局部函数结束

% ------------------------------------------------------------------------
function note_text(fig, S, txt) % 局部函数：添加图下注记
%NOTE_TEXT 图下说明注记
annotation(fig, 'textbox', [0.02 0.005 0.96 0.04], 'String', txt, ... % 在图下方加说明文本框
  'EdgeColor', 'none', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ... % 文本框无边框左对齐
  'FontName', S.fontCN, 'FontSize', S.fsNote, 'Color', [0.25 0.25 0.25]); % 注记字体与灰色
end % 局部函数结束
