/*
 * yaopy.i
 *
 * Main function to call the pygtk GUI to yao.
 * syntax: yorick -i yaopy.i [yaoparfile]
 *
 * This plugin requires yao.py and yao.glade. These are looked for, but
 * the path can be forced setting Y_PYTHON and Y_GLADE
 *
 * This file is part of the yao package, an adaptive optics
 * simulation tool.
 *
 * $Id: yaopy.i,v 1.6 2007-12-19 15:45:32 frigaut Exp $
 *
 * Copyright (c) 2002-2007, Francois Rigaut
 *
 * This program is free software; you can redistribute it and/or  modify it
 * under the terms of the GNU General Public License  as  published  by the
 * Free Software Foundation; either version 2 of the License,  or  (at your
 * option) any later version.
 *
 * This program is distributed in the hope  that  it  will  be  useful, but
 * WITHOUT  ANY   WARRANTY;   without   even   the   implied   warranty  of
 * MERCHANTABILITY or  FITNESS  FOR  A  PARTICULAR  PURPOSE.   See  the GNU
 * General Public License for more details (to receive a  copy  of  the GNU
 * General Public License, write to the Free Software Foundation, Inc., 675
 * Mass Ave, Cambridge, MA 02139, USA).
 *
 * $Log: yaopy.i,v $
 * Revision 1.6  2007-12-19 15:45:32  frigaut
 * - implemented yao.conf which defines the YAO_SAVEPATH directory where
 * all temporary files and result files will be saved
 * - modified yao.i and aoutil.i to save in YAO_SAVEPATH
 * - bumped version to 4.2.0
 * - slight changes to GUI (edit conf file)
 *
 * Revision 1.5  2007/12/19 13:18:59  frigaut
 * - explicit message when screens are not present/found
 * - more messages in statusbar
 * - added statusbar1 (that can hide/show) for strehl status header
 *
 * Revision 1.4  2007/12/18 19:03:20  frigaut
 * - reworked Y_PYTHON and search for yao.py
 * - added Y_GLADE and path to yao.glade
 * - now removes CVS directories in install of examples and doc
 *
 * Revision 1.3  2007/12/17 20:21:04  frigaut
 * - renamed yaogtk -> yao (and updated Makefile accordingly)
 * - gotten rid of usleep() calls in yorick -> python communication. Instead,
 * am using a pyk_flush, which send a flush request to python every seconds.
 * This is still a hack to turn around the BLOCK bug in python, but at least
 * it does not use usleep (cleaner hack?).
 * - added debug python <> yorick entry in GUI help menu (set/unset pyk_debug)
 *
 * Revision 1.2  2007/12/13 16:04:21  frigaut
 * - modification to broken Makefile
 * - reshuffling of plug_in statement
 *
 * Revision 1.1.1.1  2007/12/12 23:29:10  frigaut
 * Initial Import - yorick-yao
 *
 *
 */

// PATH to yao.py and yao.glade:
require,"pathfun.i";

if (noneof(Y_PYTHON)) \
  Y_PYTHON="./:"+Y_USER+":"+pathform(_(Y_USER,Y_SITES,Y_SITE)+"python/");
if (is_void(Y_GLADE)) \
  Y_GLADE="./:"+Y_USER+":"+pathform(_(Y_USER,Y_SITES,Y_SITE)+"glade/");
if (is_void(Y_CONF)) \
  Y_CONF="./:"+Y_USER+":"+pathform(_(Y_USER,Y_SITES,Y_SITE)+"conf/");

// try to find yao.py
path2py = find_in_path("yao.py",takefirst=1,path=Y_PYTHON);
if (is_void(path2py)) {
  // not found. bust out
  write,format="Can't find yao.py in %s nor in %s\n",Y_PYTHON;
  error,"Aborting";
 }
path2py = dirname(path2py);
write,format=" Found yao.py in %s\n",path2py;

// try to find yao.glade
path2glade = find_in_path("yao.glade",takefirst=1,path=Y_GLADE);
if (is_void(path2glade)) {
  // not found. bust out
  write,format="Can't find yao.glade in %s nor in %s\n",Y_GLADE;
  error,"Aborting";
 }
path2glade = dirname(path2glade);
write,format=" Found yao.glade in %s\n",path2glade;

require,"pyk.i";
require,"yao.i";

// set default save path
YAO_SAVEPATH=Y_USER+"yao/";
// try to find yao.conf
path2conf = find_in_path("yao.conf",takefirst=1,path=Y_CONF);
if (!is_void(path2conf)) {
  path2conf = dirname(path2conf)+"/";
  write,format=" Found and included yao.conf in %s\n",path2conf;
  require,path2conf+"yao.conf";
 }


yaopy=1; // used in yao.i to know if using pygtk GUI
if (pyk_debug==[]) pyk_debug=0;
//sleep=200;
default_dpi=dpi=60;

// spawned gtk interface
python_exec = path2py+"/yao.py";
pyk_cmd=[python_exec,swrite(format="%s",path2glade)];

// span the python process, and hook to existing _tyk_proc (see pyk.i)
_pyk_proc = spawn(pyk_cmd, _pyk_callback);

func yaopy_quit(void)
{
  pyk,"gtk.main_quit()";
  write,"\n*** Python interface killed, quitting ***";
  quit;
}

func read_conf(void)
{
  include,path2conf+"yao.conf",1;
  mkdirp,YAO_SAVEPATH;
}

func save_conf(void)
{
  extern path2conf;
  if (is_void(path2conf)) path2conf=Y_USER;
  
  if (catch(0x02)) {
    pyk_error,swrite(format="Can not create %syao.conf. Permission problem?",path2conf);
    return;
  }
  f=open(path2conf+"yao.conf","w");
  write,f,"/* yao.conf";
  write,f," * this file is included by yaopy.i";
  write,f," * definition of the path and possibly other variables";
  write,f," * e.g. pyk_debug=1";
  write,f," */";
  //  write,f,"extern YAO_SAVEPATH;\n";
  write,f,format="YAO_SAVEPATH=\"%s\";\n",YAO_SAVEPATH;
  close,f;
  write,format="Configuration saved in %syao.conf\n",path2conf;
  gui_message,swrite(format="Configuration saved in %syao.conf",path2conf);
  mkdirp,YAO_SAVEPATH;
}

func yao_win_init(parent_id)
{
  window,0,style="aosimul3.gs",dpi=dpi,width=long(550*(dpi/50.)),
    height=long(425*(dpi/50.)),wait=1,parent=parent_id;
}

func wrap_create_phase_screens(void)
{
  if (atm) prefix=dirname((*atm.screen)(1));
  else prefix=Y_USER+"data";

  if (catch(0x02)) {
    pyk_error,swrite(format="Can not create %s. Permission problem?",prefix);
    clean_progressbar;
    pyk,"set_cursor_busy(0)";
    return;
    //    error,swrite(format="Can not create %s. Permission problem?",prefix);
  }
  mkdirp,prefix;

  l=2048;
  w=256;
  gui_message,swrite(format="Creating phase screens %dx%d in %s",l,w,prefix);
  write,format="Creating phase screens %dx%d in %s",l,w,prefix;
  CreatePhaseScreens,2048,256,prefix=prefix+"/screen";
  gui_message,swrite(format="Done: Phase screens created in %s",prefix);
  write,format="Done: Phase screens created in %s\n",prefix;
  pyk,"set_cursor_busy(0)";
}

func clean_progressbar(void)
{
  gui_progressbar_text,"";
  gui_progressbar_frac,0.;
}

func gui_progressbar_frac(frac)
{
  pyk,swrite(format="progressbar.set_fraction(%f)",float(frac));  
}

func gui_progressbar_text(text)
{
  pyk,swrite(format="progressbar.set_text('%s')",text);  
}

func gui_message(msg)
{
  pyk,swrite(format="statusbar.push(1,'%s')",msg);
}

func gui_message1(msg)
{
  pyk,swrite(format="statusbar1.push(1,'%s')",msg);
}

statusbar1_visible=0;
func gui_show_statusbar1(void)
{
  extern statusbar1_visible;
  if (statusbar1_visible) return;
  pyk,"statusbar1.show()";
  statusbar1_visible=1;
}

func gui_hide_statusbar1(void)
{
  extern statusbar1_visible;
  if (!statusbar1_visible) return;
  pyk,"statusbar1.hide()";
  statusbar1_visible=0;
}

func okvec2str(okvec) {
  if (allof(okvec == 0)) return "-1";
  return "["+strtrim(strJoin(swrite(format="%d",where(okvec)),","))+"]";
}

// wrapper functions

func set_aoinit_flags(disp,clean,forcemat,svd,keepdmconfig)
{
  extern aoinit_disp,aoinit_clean,aoinit_forcemat,aoinit_svd,aoinit_keepdmconfig;
  aoinit_disp=disp;
  aoinit_clean=clean;
  aoinit_forcemat=forcemat;
  aoinit_svd=svd;
  aoinit_keepdmconfig=keepdmconfig;
}

func set_loop_gain(gain)
{
  loop.gain=gain;
}

func toggle_im_imav (imavg)
{
  extern dispImImav;

  if (imavg) dispImImav=imavg;
  else dispImImav=3-dispImImav;
}

func change_target_lambda(lambda)
{
  (*target.lambda)(0)=lambda;
  if (target._ntarget==1) {
    *target.dispzoom=(*target.lambda)(0)*1e-6/4.848e-6/tel.diam*sim.pupildiam/2;
    disp2D,im,*target.xposition,*target.yposition,1,zoom=*target.dispzoom,init=1,nolimits=1;
  }
}

func change_zenith_angle(zen)
{
   gs.zenithangle=zen;
   aoinit;
}

func change_dr0(dr0) {
  atm.dr0at05mic=dr0;
  getTurbPhaseInit;
}

func change_seeing(seeing) {  //seeing at 550 (V band)
  r0at500 = (0.500e-6/seeing/4.848e-6)*(500./550.)^1.2;
  atm.dr0at05mic     = tel.diam/r0at500;
  getTurbPhaseInit;
}


func do_inter_disp {
  doInter,disp=1,sleep=sleep;
}

func do_aoinit_disp {
  stop;  // in case we are running another loop.
  aoinit,disp=1,dpi=default_dpi;
  pyk,"set_cursor_busy(0)";
}

func do_aoloop_disp {
  aoloop,disp=1,dpi=default_dpi;
  plsys,1;
  animate,0;
  animate,1;
  pyk,"set_cursor_busy(0)";
}

func toggle_animate(state)
{
  plsys,1;
  if (state==0) fma;
  if (state!=[]) animate,state; else animate;
}

func set_okdm(dmnum,ok)
{
  extern okdm,okwfs;
  okdm(dmnum)=ok;
}

func set_okwfs(wfsnum,ok)
{
  extern okdm,okwfs;
  okwfs(wfsnum)=ok;

  if (sum(okwfs)==0) {
    pyk,"wfs_panel_set_sensitivity(0,0)";
  } else {
    w1 = where(okwfs)(1);
    if (wfs(w1).type=="hartmann") pyk,"wfs_panel_set_sensitivity(1,1)"; \
    else if (wfs(w1).type=="curvature") pyk,"wfs_panel_set_sensitivity(1,2)";
    gui_update_wfs,w1;
  }
  //  usleep,50
  pyk,"yo2py_flush";
}

func dm_reset
{
  extern okdm,okwfs;
  if (noneof(okdm)) return;
  for (i=1;i<=ndm;i++) {
    if (okdm(i)) dm(i)._command=&((*dm(i)._command)*0.f);
  }
  wfsMesHistory*=0.0f;
}

func dm_flatten
{
  extern okdm,okwfs;
  if (noneof(okdm)) return;
  for (i=1;i<=ndm;i++) {
    if (okdm(i)) dm(i)._command=&((*dm(i)._command)*0.f);
  }
}

func dm_hyst(hystval)
{
  extern okdm,okwfs;
  if (noneof(okdm)) return;
  for (i=1;i<=ndm;i++) {
    if (okdm(i)) dm(i).hyst=hystval/100.;
  }
}

func dm_gain(gainval)
{
  extern okdm,okwfs;
  if (noneof(okdm)) return;
  for (i=1;i<=ndm;i++) {
    if (okdm(i)) dm(i).gain=gainval;
  }
}

func dm_xmisreg(xmisreg)
{
  extern okdm,okwfs;
  if (noneof(okdm)) return;
  for (i=1;i<=ndm;i++) {
    if (okdm(i)) {
      dm(i).misreg(1)=xmisreg/100.*dm(i).pitch;
    }
  }
}

func dm_ymisreg(ymisreg)
{
  extern okdm,okwfs;
  if (noneof(okdm)) return;
  for (i=1;i<=ndm;i++) {
    if (okdm(i)) {
      dm(i).misreg(2)=ymisreg/100.*dm(i).pitch;
    }
  }
}

func dm_satvolt(satvolt)
{
  extern okdm,okwfs;
  if (noneof(okdm)) return;
  for (i=1;i<=ndm;i++) {
    if (okdm(i)) {
      dm(i).maxvolt=satvolt;
    }
  }
}

func set_wfs_noise(nse)
{
  extern okdm,okwfs;
  if (noneof(okwfs)) return;
  for (i=1;i<=nwfs;i++) {
    if (okwfs(i)) wfs(i).noise=nse;
  }
}

func set_gs_alt(gsalt)
{
  wfs(wfsvec).gsalt=wfs(wfsvec).gsalt*0+gsalt;
  getTurbPhaseInit,skipReadPhaseScreens=1;
  for(ll=1;ll<=nwfs;ll++) {
    ShWfsInit,ipupil,ll,silent=1;
  }
}

func set_gs_depth(gsdepth)
{
  wfs(wfsvec).gsdepth=wfs(wfsvec).gsdepth*0+gsdepth;
  getTurbPhaseInit,skipReadPhaseScreens=1;
  for(ll=1;ll<=nwfs;ll++) {
    ShWfsInit,ipupil,ll,silent=1;
  }
}

func set_gs_mag(gsmag)
{
  extern okdm,okwfs;
  if (noneof(okwfs)) return;
  for (i=1;i<=nwfs;i++) {
    if (okwfs(i)) {
      wfs(i).gsmag=gsmag;
      if (wfs(i).type=="curvature") {
        CurvWfs,,,i,init=1,disp=0,silent=1;
      } else {
        ShWfsInit,ipupil,i,silent=1;
      }
    }
  }
}

func set_wfs_ron(ron)
{
  extern okdm,okwfs;
  if (noneof(okwfs)) return;
  for (i=1;i<=nwfs;i++) if (okwfs(i)) wfs(i).ron=ron;
}

func wfs_subtract_background(state)
{
  wfs(wfsvec)._bckgrdsub=state;
}

func wfs_set_uptt(state)
{
  wfs(wfsvec).correctUpTT=state;
}

func set_wfs_kernel(value)
{
  wfs(wfsvec).kernel=wfs(wfsvec).kernel*0+value;
  for(ll=1;ll<=nwfs;ll++) {
    ShWfsInit,ipupil,ll,silent=1;
  }
}

func set_wfs_threshold(threshold)
{
  extern okdm,okwfs;
  if (noneof(okwfs)) return;
  for (i=1;i<=nwfs;i++) if (okwfs(i)) wfs(i).shthreshold=threshold;
}

func set_wfs_nintegcycles(nic)
{
  extern okdm,okwfs;
  if (noneof(okwfs)) return;
  for (i=1;i<=nwfs;i++) if (okwfs(i)) wfs(i).nintegcycles=nic;
}

func set_wfs_efd(efd)
{
  extern okdm,okwfs;
  if (noneof(okwfs)) return;
  for (i=1;i<=nwfs;i++) {
    if (okwfs(i)) {
      wfs(i).l=efd;
      CurvWfs,,,i,init=1,disp=0,silent=1;

    }
  }
}

func gui_update_wfs(num)
{
  pyk,swrite(format="y_set_checkbutton('subtract_background',%d)",long(wfs(num)._bckgrdsub));
  pyk,swrite(format="y_set_checkbutton('noise',%d)",long(wfs(num).noise));
  pyk,swrite(format="y_set_checkbutton('correct_up_tt',%d)",long(wfs(num).correctUpTT));  
  pyk,swrite(format="y_parm_update('efd',%f)",float(wfs(num).l));
  pyk,swrite(format="y_parm_update('gsmag',%f)",float(wfs(num).gsmag));
  pyk,swrite(format="y_parm_update('gsalt',%f)",float(wfs(num).gsalt));
  pyk,swrite(format="y_parm_update('gsdepth',%f)",float(wfs(num).gsdepth));
  pyk,swrite(format="y_parm_update('ron',%f)",float(wfs(num).ron));
  pyk,swrite(format="y_parm_update('sh_threshold',%f)",float(wfs(num).shthreshold));
  pyk,swrite(format="y_parm_update('sh_kernel',%f)",float(wfs(num).kernel));
  pyk,swrite(format="y_parm_update('ninteg_cycles',%f)",float(wfs(num).nintegcycles));
}

record_shot=0;
window3_created=0;
func plotMTF(i,init=)
{
  extern mtf_reference,mtf_airy,record_shot;
  extern airy,window3_created;
  
  if (init) {
    if (window3_created==0) {
      dimwin=450*default_dpi/80;
      window,3,height=dimwin,width=dimwin,dpi=default_dpi,wait=1;
      window3_created=1;
    }
    window,0;
    mtf=eclat(abs(fft(airy,1)));
    mtf=cart2pol(mtf);
    mtf=mtf/mtf(1);
    mtf_airy=mtf(,avg);
    return;
  }
  if (dispImImav==2) {
    mtf=eclat(abs(fft(imav(,,1),1)));
  } else {
    mtf=eclat(abs(fft(im(,,1),1)));
  }
  mtf=cart2pol(mtf);
  if (mtf(1)==0) return;
  mtf=mtf/mtf(1);
  if (record_shot) {
    mtf_reference=mtf(,avg);
    record_shot=0;
  }
  window,3;
  fma;
  plg,mtf(,avg);
  range,0.,1.;
  if (mtf_reference!=[]) plg,mtf_reference,color="red";
  plg,mtf_airy,color="green";
  xytitles,"spatial frequency","MTF";
  window,0;
}

func toggle_userplot_mtf
{
  if (userPlot!=[]) userPlot=[];
  else {
    userPlot=plotMTF;
    plotMTF,init=1;
  }
}

func plotDphi(i,init=)
{
  extern dphi_reference,mtf_airy,dphi_atmos,record_shot;
  extern airy,imax,dphi_x,window3_created;
  
  if (init) {
    if (window3_created==0) {
      dimwin=450*default_dpi/80;
      window,3,height=dimwin,width=dimwin,dpi=default_dpi,wait=1;
      window3_created=1;
    }
    window,0;
    mtf=eclat(abs(fft(airy,1)));
    mtf=cart2pol(mtf);
    mtf=mtf/mtf(1);
    mtf_airy=mtf(,avg);
    imax=max(where(mtf_airy>1e-5));
    dphi_x=span(0.,tel.diam,imax);
    clip,mtf_airy,1e-5,;
    dphi_atmos=6.88*(dphi_x/tel.diam*atm.dr0at05mic*0.5/(*target.lambda)(0))^1.666;
    return;
  }

  if (dispImImav==2) {
    mtf=eclat(abs(fft(imav(,,1),1)));
  } else {
    mtf=eclat(abs(fft(im(,,1),1)));
  }
  mtf=cart2pol(mtf);
  if (mtf(1)==0) return;
  mtf=mtf/mtf(1);
  mtf=mtf(,avg);
  mtf=mtf/mtf_airy;
  dphi=-2*log(mtf);
  
  if (record_shot) {
    dphi_reference=dphi;
    record_shot=0;
  }
  window,3;
  fma;
  plg,dphi(1:imax),dphi_x;
  range,0.,10.;
  if (dphi_reference!=[]) plg,dphi_reference,color="red";
  plg,dphi_atmos,dphi_x,color="green";
  xytitles,"separation","Dphi";
  window,0;
}

func toggle_userplot_dphi
{
  if (userPlot!=[]) userPlot=[];
  else {
    userPlot=plotDphi;
    plotDphi,init=1;
  }
}

func wrap_aoread(void)
{
  stop;  // in case we are running another loop.
  aoread,yaopardir+"/"+yaoparfile;
  gui_update;
  //  usleep,100; // why do I have to do that for it to work ????
  pyk,"set_cursor_busy(0)";
}

func gui_update(void)
{
  extern dispImImav,okdm,okwfs;

  pyk,swrite(format="pyk_debug = %d",pyk_debug);
  pyk,swrite(format="glade.get_widget('debug').set_active(%d)",pyk_debug);

  if (is_void(path2conf)) save_conf;
  write,format="Results will be saved in %s\n",YAO_SAVEPATH;
  gui_message,swrite(format="Results will be saved in %s",YAO_SAVEPATH);
  
  require,"string.i";
  pyk,swrite(format="yuserdir = '%s'",streplace(Y_USER,strfind("~",Y_USER),get_env("HOME"))); 
  pyk,swrite(format="yaopardir = '%s'",yaopardir); 
    
  if (strlen(yaoparfile)) {
    pyk,swrite(format="y_text_parm_update('yaoparfile','%s')",yaoparfile);
    pyk,swrite(format="yaoparfile = '%s'",yaoparfile); 
  } else {
    pyk,"glade.get_widget('aoread').set_sensitive(0)";
  }
  //  usleep,100; // why do I have to do that for it to work ????
  //  pyk,"yo2py_flush";
  if (wfs==[]) return;  // then aoread has not yet occured.
  
  sim.debug=0;

  dispImImav = 1;
  ditherAmp = 0.1;
  ditherPeriod = 10;
  disp = 10;
  //  wfsMesHistory = 0;
  for (i=1;i<=ndm;i++) {dm(i)._command = &([0]);}
  
  okwfs = array(0.,nwfs);
  okdm  = array(0.,ndm);
  //  pyk,swrite(format="nwfs=%d",nwfs);
  r0at500 = tel.diam/atm.dr0at05mic;
  seeing = (0.500e-6/r0at500/4.848e-6)*(500./550.)^1.2;
  pyk,"glade.get_widget('edit').set_sensitive(1)";
  pyk,"glade.get_widget('aoread').set_sensitive(1)";
  //  pyk,"glade.get_widget('aoread').grab_focus()";
  pyk,swrite(format="y_text_parm_update('yaoparfile','%s')",yaoparfile); 
  pyk,swrite(format="window.set_title('%s')",yaoparfile); 
  pyk,swrite(format="y_parm_update('seeing',%f)",float(seeing));
  pyk,swrite(format="y_parm_update('loopgain',%f)",float(loop.gain));
  pyk,swrite(format="y_parm_update('imlambda',%f)",float((*target.lambda)(1)));
  gui_update_wfs,1;
  pyk,swrite(format="y_parm_update('dmgain',%f)",float(dm(1).gain));
  pyk,swrite(format="y_parm_update('xmisreg',%f)",float(dm(1).misreg(1)));
  pyk,swrite(format="y_parm_update('ymisreg',%f)",float(dm(1).misreg(2)));
  pyk,swrite(format="y_set_ndm(%d)",ndm);
  pyk,swrite(format="y_set_nwfs(%d)",nwfs);
  //  usleep,100; // why do I have to do that for it to work ????
  pyk,swrite(format="y_parm_update('sat_voltage',%f)",float(dm(1).maxvolt));
/*  tyk,"set ndm "+swrite(format="%d",ndm);
  tyk,"set centg "+swrite(format="%d",wfs(1).centGainOpt);

  tyk,"set hyst "+swrite(format="%f",dm(1).hyst);
  */
  //  pyk,"set_cursor_busy(0)";
}


func pyk_info(msg)
{
  if (numberof(msg)>1) msg=sum(msg+"\\n");
  // or streplace(msg,strfind("\n",msg),"\\n")
  pyk,swrite(format="pyk_info('%s')",msg)
}


func pyk_info_w_markup(msg)
{
  if (numberof(msg)>1) msg=sum(msg+"\\n");
  // or streplace(msg,strfind("\n",msg),"\\n")
  pyk,swrite(format="pyk_info_w_markup('%s')",msg)
}


func pyk_error(msg)
{
  if (numberof(msg)>1) msg=sum(msg+"\\n");
  pyk,swrite(format="pyk_error('%s')",msg)
}


func pyk_warning(msg)
{
  if (numberof(msg)>1) msg=sum(msg+"\\n");
  pyk,swrite(format="pyk_warning('%s')",msg)
}


func pyk_flush(void)
{
  pyk,"yo2py_flush";
  after,1.,pyk_flush;
}

arg     = get_argv();
if (numberof(arg)>=4) {
  yaoparfile = arg(4);
  yaopardir = dirname(yaoparfile);
  if (yaopardir==".") yaopardir=get_cwd();
  yaoparfile = basename(yaoparfile);
  if (noneof(findfiles(yaoparfile))) error,"Can't find "+yaoparfile;
  //  aoread,yaoparfile;
 } else {
  yaoparfile="";
  tmp = find_in_path("data/sh6x6.par",takefirst=1);
  if (tmp==[]) tmp=find_in_path("example/sh6x6.par",takefirst=1);
  if (tmp!=[]) yaopardir = dirname(tmp);
  if (tmp==[]) tmp=find_in_path("../data/sh6x6.par",takefirst=1);
  if (tmp==[]) tmp=find_in_path("../example/sh6x6.par",takefirst=1);
  if (tmp!=[]) yaopardir = dirname(tmp);
  else yaopardir=get_cwd();
 }

pyk_flush;
