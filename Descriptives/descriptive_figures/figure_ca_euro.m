dat_ca=[
    1991	-0.04975204
1992	-0.101968494
1993	-0.310239809
1994	-0.422382064
1995	-0.687501143
1996	-0.527255376
1997	-0.627255925
1998	-0.376783069
1999	-0.257413959
2000	0.516521533
2001	0.15268239
2002	0.768042828
2003	0.65243759
2004	2.12851356
2005	2.790486167
2006	3.708821759
2007	4.284695165
2008	3.434081854
2009	3.778841777
2010	2.872260646
2011	2.962707829
2012	2.348721274
2013	1.453351166
2014	1.51749234
2015	2.707712528
2016	2.649918509
2017	2.576098016
2018	2.358585085
2019	2.200436858
];

year=dat_ca(:,1);
CA_EURO=dat_ca(:,2);



matT=[1 5 10 15 20 25 30];
matTx=['1991';'1995'; '2000';  '2005'; '2010'; '2015'; '2020';'2030'];
%% Macro figures



   T=size(G_Y_a,2);
fig_tit=['CA_Euro'];
f = figure('Name',fig_tit);
 set(f,'Color',[1 1 1],'Position',[1 1 600 400]);
    h1=  plot(CA_EURO,'k-', 'LineWidth',2,'Markersize',2);
   hold on
%    vline([25 0]) 
   hold on;
    xlim([1 30]);
      hold on
      line([1 30], [0 0], 'Color', 'r','LineWidth',2,'Markersize',2);
      hold off
  set(gca, 'XTick', matT);
  set(gca, 'XTickLabel', matTx);
   title('German Current Account vis-à-vis the Euro Area','FontSize',15,'FontWeight','Bold');
   xlabel ('Year'); 
      ylabel ('% dev.'); 
      
  print(fullfile(FigureDir, fig_tit), '-painters', '-depsc', '-r300')
  print(fullfile(FigureDir, fig_tit), '-painters', '-dpng', '-r300')  

  
  
  %% 
dat_fig2=[  
1995	-0.687501143	2.997450663	11.32629523
1996	-0.527255376	3.21279497	9.232769831
1997	-0.627255925	3.203222599	7.373868047
1998	-0.376783069	3.377647164	7.483870968
1999	-0.257413959	3.371724901	7.133757962
2000	0.516521533	3.573579127	6.675062972
2001	0.15268239	4.478628702	4.702970297
2002	0.768042828	4.606208942	3.140096618
2003	0.65243759	5.656614984	2.245862884
2004	2.12851356	5.896080477	1.288056206
2005	2.790486167	6.323443939	-0.693641618
2006	3.708821759	5.735656666	-3.555045872
2007	4.284695165	5.448980817	-5.310734463
2008	3.434081854	5.379954369	-6.093579978
2009	3.778841777	6.190380786	-4.17101147
2010	2.872260646	5.794727812	-4.712041885
2011	2.962707829	4.677824144	-4.900938478
2012	2.348721274	4.94661805	-3.684749232
2013	1.453351166	4.72726626	-2.831142568
2014	1.51749234	4.895078618	-1.909547739
2015	2.707712528	5.257304287	0
2016	2.649918509	5.223190071	0.595238095
2017	2.576098016	5.445317243	0.986193294
2018	2.358585085	5.654278683	2.321083172
2019	2.200436858	5.600822075	3.605313093];

year=dat_fig2(:,1);
CA_EURO=dat_fig2(:,2);
CA_HH=dat_fig2(:,3);
ULC=dat_fig2(:,4);


matT2=[1 6 11 16 21 25 ];
matTx2=['1995'; '2000';  '2005'; '2010'; '2015'; '2019'];

   T=size(G_Y_a,2);
fig_tit=['CA_Euro_ULC'];
f = figure('Name',fig_tit);
 set(f,'Color',[1 1 1],'Position',[1 1 800 500]);
    h1=  plot(CA_EURO,'k-', 'LineWidth',2,'Markersize',2);
   hold on
    h2=  plot(CA_HH,'k--', 'LineWidth',2,'Markersize',2);
   hold on;
       h3=  plot(ULC,'k:', 'LineWidth',2,'Markersize',2);
   hold on;
    xlim([1 25]);
      hold on
      line([1 25], [0 0], 'Color', 'r','LineWidth',2,'Markersize',2);
      hold off
  set(gca, 'XTick', matT2);
  set(gca, 'XTickLabel', matTx2);
%    title('German Current Account vis-à-vis the Euro Area','FontSize',15,'FontWeight','Bold');
   xlabel ('Year'); 
  [h_legend,BLicons] =legend([ h1 h2 h3], {'German Current Account vis-à-vis the Eurozone (% of GDP)', 'Household Contribution to German Current Account (in % of GDP)', 'Relative Unit Labor Costs: Germany Rest of Eurozone (Relative to 2015)'}, 'Location','SouthOutside');
PatchInLegend = findobj(BLicons, 'type', 'patch');
set(PatchInLegend, 'facea', 0.5);
% set(h_legend,...
%     'Position',[0.3568 0.00933333333333333 0.3264 0.0630000000000002],...
%     'Orientation','horizontal');
    legend('boxoff');
      
  print(fullfile(FigureDir, fig_tit), '-painters', '-depsc', '-r300')
  print(fullfile(FigureDir, fig_tit), '-painters', '-dpng', '-r300') 

  
  
     T=size(G_Y_a,2);
fig_tit=['CA_Euro_ULC_2'];
f = figure('Name',fig_tit);
 set(f,'Color',[1 1 1],'Position',[1 1 800 500]);
    h1=  plot(CA_EURO,'k-', 'LineWidth',2,'Markersize',2);
   hold on
%     h2=  plot(CA_HH,'k--', 'LineWidth',2,'Markersize',2);
%    hold on;
       h3=  plot(ULC,'k:', 'LineWidth',2,'Markersize',2);
   hold on;
    xlim([1 25]);
      hold on
      line([1 25], [0 0], 'Color', 'r','LineWidth',2,'Markersize',2);
      hold off
  set(gca, 'XTick', matT2);
  set(gca, 'XTickLabel', matTx2);
%    title('German Current Account vis-à-vis the Euro Area','FontSize',15,'FontWeight','Bold');
   xlabel ('Year'); 
  [h_legend,BLicons] =legend([ h1 h3], {'German Current Account vis-à-vis the Eurozone (% of GDP)', 'Relative Unit Labor Costs: Germany Rest of Eurozone (Relative to 2015)'}, 'Location','SouthOutside');
PatchInLegend = findobj(BLicons, 'type', 'patch');
set(PatchInLegend, 'facea', 0.5);
% set(h_legend,...
%     'Position',[0.3568 0.00933333333333333 0.3264 0.0630000000000002],...
%     'Orientation','horizontal');
    legend('boxoff');
      
  print(fullfile(FigureDir, fig_tit), '-painters', '-depsc', '-r300')
  print(fullfile(FigureDir, fig_tit), '-painters', '-dpng', '-r300') 
