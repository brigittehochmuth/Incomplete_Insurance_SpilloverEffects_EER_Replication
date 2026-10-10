function line_handle = paper_zero_line(ax)
%PAPER_ZERO_LINE Consistent, visible zero reference for paper figures.

arguments
    ax (1,1) matlab.graphics.axis.Axes
end

line_handle = yline(ax,0,'--', ...
    'Color',[0.28 0.28 0.28], ...
    'LineWidth',1.15, ...
    'HandleVisibility','off');
% Do not reorder ConstantLine objects with uistack. In MATLAB R2024b,
% axes used by tiledlayout/yyaxis can contain compound children whose
% Children property cannot be reassigned by uistack, even though the line
% itself was created successfully. The reference line remains visually
% unobtrusive without changing the axes child order.
end
