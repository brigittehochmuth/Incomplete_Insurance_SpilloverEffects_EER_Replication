data_intro_update;



% %% Intro Figure
% matT=[1 5 10 15 20 25 29];
% matTx=['1991'; '1995';'2000'; '2005'; '2010';'2015' ;'2019'];
% 
% fig_tit=['Intro_fig_NFA_NX'];
% f = figure('Name',fig_tit);
% set(f,'InvertHardcopy','off','Color',[1 1 1],'Position',[1 1 900 400]);
% 
% subplot (1,2,1);
%    plot(nfa(1:29),'k-','LineWidth',1,'Markersize',2);
%     ylabel ('Percent of GDP');
%           xlabel ('Year');
%     title('Net Foreign Assets','FontSize',14,'FontWeight','Bold');
%           ylim([-5 80.8])
%       xlim([1 29])
%    hold on
%       line([1 29], [0 0], 'Color', 'r');
%       hold off
%   set(gca, 'XTick', matT);
%   set(gca, 'XTickLabel', matTx);
%  %  legend('Net Foreign Assets', 'Location', 'southwest');
%    hsp1=get(gca, 'Position');
%    
% subplot (1,2,2);
%       plot(export,'--ro','LineWidth',1,'Markersize',2);
%       xlim([1 29]);
%       hold on
%    plot(import,':bs','LineWidth',1.5,'Markersize',2);
%       xlim([1 29]);
%     title('Exports vs. Imports','FontSize',14,'FontWeight','Bold');
%       hold off
%    set(gca, 'XTick', matT);
%   set(gca, 'XTickLabel', matTx);
%     legend('Exports', 'Imports', 'Location', 'northwest');
%     legend('boxoff')
%    xlabel ('Year');
%    ylabel ('Percent of GDP')
% 
%    print(fullfile(FigureDir, fig_tit), '-painters', '-depsc', '-r300')
%    print(fullfile(FigureDir, fig_tit), '-painters', '-dpng', '-r300')

   
   
   %% Intro Figure
matT=[1 5 10 15 20 25 29];
matTx=['1991'; '1995';'2000'; '2005'; '2010';'2015' ;'2019'];

fig_tit=['Intro_fig_U_NFA_NX'];
f = figure('Name',fig_tit);
set(f,'InvertHardcopy','off','Color',[1 1 1],'Position',[1 1 1200 450]);


subplot (1,3,1);
   plot(u_rate(1:29),'k-','LineWidth',1,'Markersize',2);
    ylabel ('Percent of GDP');
          xlabel ('Year');
    title('Unemployment Rate','FontSize',14,'FontWeight','Bold');
%           ylim([-5 80.8])
      xlim([1 29])
   hold on
      line([1 29], [0 0], 'Color', 'r');
      hold off
  set(gca, 'XTick', matT);
  set(gca, 'XTickLabel', matTx);
 %  legend('Net Foreign Assets', 'Location', 'southwest');
   hsp1=get(gca, 'Position');


subplot (1,3,2);
   plot(nfa(1:29),'k-','LineWidth',1,'Markersize',2);
    ylabel ('Percent of GDP');
          xlabel ('Year');
    title('Net Foreign Assets','FontSize',14,'FontWeight','Bold');
          ylim([-5 80.8])
      xlim([1 29])
   hold on
      line([1 29], [0 0], 'Color', 'r');
      hold off
  set(gca, 'XTick', matT);
  set(gca, 'XTickLabel', matTx);
 %  legend('Net Foreign Assets', 'Location', 'southwest');
   hsp1=get(gca, 'Position');
   
%    subplot (1,3,2);
%    plot(germany_CA(1:29),'k-','LineWidth',1,'Markersize',2);
%     ylabel ('Percent of GDP');
%           xlabel ('Year');
%     title('Current Account','FontSize',14,'FontWeight','Bold');
%           ylim([-3 10])
%       xlim([1 29])
%    hold on
%       line([1 29], [0 0], 'Color', 'r');
%       hold off
%   set(gca, 'XTick', matT);
%   set(gca, 'XTickLabel', matTx);
%  %  legend('Net Foreign Assets', 'Location', 'southwest');
%    hsp1=get(gca, 'Position');
%    
   
subplot (1,3,3);
      plot(export,'k-','LineWidth',1,'Markersize',2);
      xlim([1 29]);
      hold on
   plot(import,'k:','LineWidth',1.5,'Markersize',2);
      xlim([1 29]);
    title('Exports vs. Imports','FontSize',14,'FontWeight','Bold');
      hold off
   set(gca, 'XTick', matT);
  set(gca, 'XTickLabel', matTx);
    legend('Exports', 'Imports', 'Location', 'northwest');
    legend('boxoff')
   xlabel ('Year');
   ylabel ('Percent of GDP')

   print(fullfile(FigureDir, fig_tit), '-painters', '-depsc', '-r300')
   print(fullfile(FigureDir, fig_tit), '-painters', '-dpng', '-r300')
   
% %% Total Compensation by Sector/Total Value added
%    fig_tit=['Intro_comp_VA'];
% f = figure('Name',fig_tit);
% set(f,'InvertHardcopy','off','Color',[1 1 1],'Position',[1 1 900 400]);
% 
% subplot (1,2,1);
%       plot(Ind_Comp_VA_DE,'k-','LineWidth',1,'Markersize',2);
%       xlim([5 29]);
%       hold on
%    plot(Ind_Comp_VA_EA,'k:','LineWidth',1.5,'Markersize',2);
%       xlim([5 29]);
%       ylim([0.08 0.2]);
%     title('Industry','FontSize',14,'FontWeight','Bold');
%       hold off
%   set(gca, 'XTick', matT);
%   set(gca, 'XTickLabel', matTx);
%     legend('Germany', 'Euro Area', 'Location', 'northwest');
%         legend('boxoff')
%    xlabel ('Year');
%    ylabel ('Percent of Total Value Added')
%    
% subplot (1,2,2);
%       plot(Serv_Comp_VA_DE,'k-','LineWidth',1,'Markersize',2);
%       xlim([5 29]);
%       hold on
%    plot(Serv_Comp_VA_EA,'k:','LineWidth',1.5,'Markersize',2);
%       xlim([5 29]);
%     title('Services','FontSize',14,'FontWeight','Bold');
%       hold off
%    set(gca, 'XTick', matT);
%   set(gca, 'XTickLabel', matTx);
%     legend('Germany', 'Euro Area', 'Location', 'northwest');
%         legend('boxoff')
%    xlabel ('Year');
%    ylabel ('Percent of Total Value Added')
% 
%    print(fullfile(FigureDir, fig_tit), '-painters', '-depsc', '-r300')
%    print(fullfile(FigureDir, fig_tit), '-painters', '-dpng', '-r300')
%    
%    
%    %% Total Compensation by Sector/Total Value added
%    fig_tit=['Intro_comp_VA_Service'];
% f = figure('Name',fig_tit);
% set(f,'InvertHardcopy','off','Color',[1 1 1],'Position',[1 1 900 400]);
% 
% subplot (1,2,1);
%       plot(Serv_T_VA_DE,'k-','LineWidth',1,'Markersize',2);
%       xlim([5 29]);
%       hold on
%    plot(Serv_T_VA_EA,'k:','LineWidth',1.5,'Markersize',2);
%       xlim([5 29]);
% %       ylim([0.16 0.23]);
%     title('Tradable Services','FontSize',14,'FontWeight','Bold');
%       hold off
%   set(gca, 'XTick', matT);
%   set(gca, 'XTickLabel', matTx);
%     legend('Germany', 'Euro Area', 'Location', 'northwest');
%         legend('boxoff')
%    xlabel ('Year');
%    ylabel ('Percent of Total Value Added')
%    
% subplot (1,2,2);
%       plot(Serv_NT_VA_DE,'k-','LineWidth',1,'Markersize',2);
%       xlim([5 29]);
%       hold on
%    plot(Serv_NT_VA_EA,'k:','LineWidth',1.5,'Markersize',2);
% %          ylim([0.16 0.23]);
%    xlim([5 29]);
%     title('Non-Tradable Services','FontSize',14,'FontWeight','Bold');
%       hold off
%    set(gca, 'XTick', matT);
%   set(gca, 'XTickLabel', matTx);
%     legend('Germany', 'Euro Area', 'Location', 'northwest');
%         legend('boxoff')
%    xlabel ('Year');
%    ylabel ('Percent of Total Value Added')
% 
%    print(fullfile(FigureDir, fig_tit), '-painters', '-depsc', '-r300')
%    print(fullfile(FigureDir, fig_tit), '-painters', '-dpng', '-r300')
%    
%    
   
   
    %% Total Compensation by Sector/Total Value added
   fig_tit=['Intro_comp_VA_Service'];
f = figure('Name',fig_tit);
set(f,'InvertHardcopy','off','Color',[1 1 1],'Position',[1 1 1200 450]);


subplot (1,3,1);
      plot(Ind_Comp_VA_DE,'k-','LineWidth',1,'Markersize',2);
      xlim([5 29]);
      hold on
   plot(Ind_Comp_VA_EA,'k:','LineWidth',1.5,'Markersize',2);
      xlim([5 29]);
      ylim([0.08 0.2]);
    title('Industry','FontSize',14,'FontWeight','Bold');
      hold off
  set(gca, 'XTick', matT);
  set(gca, 'XTickLabel', matTx);
    legend('Germany', 'Euro Area', 'Location', 'northwest');
        legend('boxoff')
   xlabel ('Year');
   ylabel ('Percent of Total Value Added')

subplot (1,3,2);
      plot(Serv_T_VA_DE,'k-','LineWidth',1,'Markersize',2);
      xlim([5 29]);
      hold on
   plot(Serv_T_VA_EA,'k:','LineWidth',1.5,'Markersize',2);
      xlim([5 29]);
%       ylim([0.16 0.23]);
    title('Tradable Services','FontSize',14,'FontWeight','Bold');
      hold off
  set(gca, 'XTick', matT);
  set(gca, 'XTickLabel', matTx);
    legend('Germany', 'Euro Area', 'Location', 'northwest');
        legend('boxoff')
   xlabel ('Year');
   ylabel ('Percent of Total Value Added')
   
subplot (1,3,3);
      plot(Serv_NT_VA_DE,'k-','LineWidth',1,'Markersize',2);
      xlim([5 29]);
      hold on
   plot(Serv_NT_VA_EA,'k:','LineWidth',1.5,'Markersize',2);
%          ylim([0.16 0.23]);
   xlim([5 29]);
    title('Non-Tradable Services','FontSize',14,'FontWeight','Bold');
      hold off
   set(gca, 'XTick', matT);
  set(gca, 'XTickLabel', matTx);
    legend('Germany', 'Euro Area', 'Location', 'northwest');
        legend('boxoff')
   xlabel ('Year');
   ylabel ('Percent of Total Value Added')

   print(fullfile(FigureDir, fig_tit), '-painters', '-depsc', '-r300')
   print(fullfile(FigureDir, fig_tit), '-painters', '-dpng', '-r300')
   
% %% Intro Figure
% 
% matT=[1 5 10 15 20 25 29];
% matTx=['1991'; '1995';'2000'; '2005'; '2010';'2015' ;'2019'];
% 
% fig_tit=['Intro_fig'];
% f = figure('Name',fig_tit);
% set(f,'InvertHardcopy','off','Color',[1 1 1],'Position',[1 1 1200 1200]);
% subplot (2,2,1);
%    plot(nfa(1:29),'k-','LineWidth',1,'Markersize',2);
%     ylabel ('Percent of GDP');
%           xlabel ('Year');
%     title('Net Foreign Assets','FontSize',14,'FontWeight','Bold');
%           ylim([-12 80.8])
%       xlim([1 29])
%    hold on
%       line([1 29], [0 0], 'Color', 'r');
%       hold off
%   set(gca, 'XTick', matT);
%   set(gca, 'XTickLabel', matTx);
%  %  legend('Net Foreign Assets', 'Location', 'southwest');
%    hsp1=get(gca, 'Position');
% subplot2=subplot (2,2,2);
%       plot(ca(1:29),'k-','LineWidth',1,'Markersize',2);
%     ylabel ('Percent of GDP');
%    xlim([1 29]);
%     title('Current Account','FontSize',14,'FontWeight','Bold');
%    hold on
%       line([1 29], [0 0], 'Color', 'r');
%       hold off
%   set(gca, 'XTick', matT);
%   set(gca, 'XTickLabel', matTx);
%  %  legend('Current Account', 'Location', 'northwest');
%  % legend('boxoff')
%      xlabel ('Year');
%    hsp1=get(gca, 'Position');
%    set(subplot2,'YColor',...
%     [0.235294118523598 0.235294118523598 0.235294118523598]);
% 
% 
% subplot (2,2,3);
%    plot(export,'--ro','LineWidth',1,'Markersize',2);
%       xlim([1 29]);
%       hold on
%    plot(import,':bs','LineWidth',1.5,'Markersize',2);
%       xlim([1 29]);
%     title('Exports vs. Imports','FontSize',14,'FontWeight','Bold');
%       hold off
%    set(gca, 'XTick', matT);
%   set(gca, 'XTickLabel', matTx);
%     legend('Exports', 'Imports', 'Location', 'northwest');
%     legend('boxoff')
%    xlabel ('Year');
%    ylabel ('Percent of GDP')
%    
% subplot (2,2,4);
% plot(saving,'--ro','LineWidth',1,'Markersize',2);
%       xlim([1 29]);
%       hold on
%    plot(invest,':bs','LineWidth',1.5,'Markersize',2);
%       xlim([1 29]);
%     title('Savings vs. Investment','FontSize',14,'FontWeight','Bold');
%       hold off
%    set(gca, 'XTick', matT);
%   set(gca, 'XTickLabel', matTx);
%      legend('Savings', 'Investment ', 'Location', 'northwest');
%   legend('boxoff')
%    xlabel ('Year');
%    ylabel ('Percent of GDP')
% 
%    print(fullfile(FigureDir, fig_tit), '-painters', '-depsc', '-r300')
%    print(fullfile(FigureDir, fig_tit), '-painters', '-dpng', '-r300')
% 
%    
%    
%    
%    % 
% fig_tit=['Imports_vs_Exports'];
% f = figure('Name',fig_tit);
% set(f,'InvertHardcopy','off','Color',[1 1 1],'Position',[1 1 900 600]);
%       plot(export,'--ro','LineWidth',1,'Markersize',2);
%       xlim([1 29]);
%       hold on
%    plot(import,':bs','LineWidth',1.5,'Markersize',2);
%       xlim([1 29]);
%     title('Exports vs. Imports','FontSize',14,'FontWeight','Bold');
%       hold off
%    set(gca, 'XTick', matT);
%   set(gca, 'XTickLabel', matTx);
%     legend('Exports', 'Imports', 'Location', 'northwest');
%     legend('boxoff')
%    xlabel ('Year');
%    ylabel ('Percent of GDP')
%       print(fullfile(FigureDir, fig_tit), '-painters', '-depsc', '-r300')
%    print(fullfile(FigureDir, fig_tit), '-painters', '-dpng', '-r300')
%    
%    
%    
%    fig_tit=['VA_T_NT'];
% f = figure('Name',fig_tit);
% set(f,'InvertHardcopy','off','Color',[1 1 1],'Position',[1 1 900 600]);
%       plot(VA_VerarbeitendesGewerbe,'k-','LineWidth',1,'Markersize',2);
%       xlim([5 25]);
%       hold on
%    plot(VA_Service_T,'b--','LineWidth',1.5,'Markersize',2);
%       xlim([5 25]);
%       hold on;
%         plot(VA_Service_NT,'r:','LineWidth',1.5,'Markersize',2);
%       xlim([5 25]); 
%     title('Value Added of Tradables vs. Non-Tradables','FontSize',14,'FontWeight','Bold');
%       hold off
%    set(gca, 'XTick', matT);
%   set(gca, 'XTickLabel', matTx);
%     legend('Manufacturing', 'Tradable Services','Non-Tradable Services', 'Location', 'southwest');
%     legend('boxoff')
%    xlabel ('Year');
%    ylabel ('Normalized to 1 (in 2005)')
%    
%    print(fullfile(FigureDir, fig_tit), '-painters', '-depsc', '-r300')
%    print(fullfile(FigureDir, fig_tit), '-painters', '-dpng', '-r300')
%    
%    
%    
%    %% Wage Sum
%    
%       fig_tit=['LS_T_NT'];
% f = figure('Name',fig_tit);
% set(f,'InvertHardcopy','off','Color',[1 1 1],'Position',[1 1 900 600]);
%       plot(LS_VerarbeitendesGewerbe,'k-','LineWidth',1,'Markersize',2);
%       xlim([5 25]);
%       hold on
%    plot(LS_Service_T,'b--','LineWidth',1.5,'Markersize',2);
%       xlim([5 25]);
%       hold on;
%         plot(LS_Service_NT,'r:','LineWidth',1.5,'Markersize',2);
%       xlim([5 25]); 
%     title('Wage Sum of Tradables vs. Non-Tradables','FontSize',14,'FontWeight','Bold');
%       hold off
%    set(gca, 'XTick', matT);
%   set(gca, 'XTickLabel', matTx);
%     legend('Manufacturing', 'Tradable Services','Non-Tradable Services', 'Location', 'northwest');
%     legend('boxoff')
%    xlabel ('Year');
%    ylabel ('Normalized to 1 (in 2005)')
%       print(fullfile(FigureDir, fig_tit), '-painters', '-depsc', '-r300')
%    print(fullfile(FigureDir, fig_tit), '-painters', '-dpng', '-r300')
%    
%    
%       %% Arbeitnehmer
%    
%       fig_tit=['AN_T_NT'];
% f = figure('Name',fig_tit);
% set(f,'InvertHardcopy','off','Color',[1 1 1],'Position',[1 1 900 600]);
%       plot(AN_VerarbeitendesGewerbe,'k-','LineWidth',1,'Markersize',2);
%       xlim([5 25]);
%       hold on
%    plot(AN_Service_T,'b--','LineWidth',1.5,'Markersize',2);
%       xlim([5 25]);
%       hold on;
%         plot(AN_Service_NT,'r:','LineWidth',1.5,'Markersize',2);
%       xlim([5 25]); 
%     title('Employees in Tradable vs. Non-Tradable Sector','FontSize',14,'FontWeight','Bold');
%       hold off
%    set(gca, 'XTick', matT);
%   set(gca, 'XTickLabel', matTx);
%     legend('Manufacturing', 'Tradable Services','Non-Tradable Services', 'Location', 'northwest');
%     legend('boxoff')
%    xlabel ('Year');
%    ylabel ('Normalized to 1 (in 2005)')
%       print(fullfile(FigureDir, fig_tit), '-painters', '-depsc', '-r300')
%    print(fullfile(FigureDir, fig_tit), '-painters', '-dpng', '-r300')
%    
% %    
% %    
% %    
% % %% Intro Figure
% % 
% % fig_tit=['Intro_SR_skill'];
% % f = figure('Name',fig_tit);
% % set(f,'InvertHardcopy','off','Color',[1 1 1],'Position',[1 1 700 700]);
% %  h1=  plot(sr_low,'r:','LineWidth',1.5,'Markersize',2);
% %    hold on;
% %   h2= plot(sr_high,'b--','LineWidth',1.5,'Markersize',2);
% %     ylabel ('Savings Rate in Percent');
% %           xlabel ('Year');
% %       xlim([4 25])
% %       ylim([8 16])
% %    hold on
% %       line([1 25], [0 0], 'Color', 'r');
% %       hold off
% %   set(gca, 'XTick', matT);
% %   set(gca, 'XTickLabel', matTx);
% %      legend('Low-skilled Workers', 'High-skilled Workers', 'Location', 'northwest');
% %      legend('boxoff')
% %      hsp1=get(gca, 'Position');
% % 
% %    print(fullfile(FigureDir, fig_tit), '-painters', '-depsc', '-r300')
% %    print(fullfile(FigureDir, fig_tit), '-painters', '-dpng', '-r300')
