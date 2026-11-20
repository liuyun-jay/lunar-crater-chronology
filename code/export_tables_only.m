% ========================================================================
% 文件名：export_tables_only.m
% 作用：只把已经保存的 results.mat 重新导出为 CSV，不重复蒙特卡洛计算。
% 通俗原理：如果只想刷新表格或某个表格格式改坏了，直接读取结果文件
%     再导出即可，比重新运行几分钟的主流程快得多。
% 输入：results/results.mat。
% 输出：results/ 下的 CSV 表格。
% ========================================================================
%% EXPORT_TABLES_ONLY 仅从已保存的 results.mat 导出论文表格
% 用途：计算出错或只想刷新表格时，无需重跑蒙特卡洛。

clear; clc; % 清空工作区与命令行
here = fileparts(mfilename('fullpath')); % 取本文件所在目录
addpath(here); % 加入搜索路径

cfg0 = config(); % 读取项目配置
S = load(fullfile(cfg0.dirResults, 'results.mat'), 'R', 'ST', 'cfg'); % 加载已保存的结果数据
s10_tables(S.R, S.ST, S.cfg); % 重新导出论文表格
fprintf('表格导出完成。\n'); % 提示导出完成
