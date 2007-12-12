<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>yao php</title>
<script type="text/javascript" src="scripts.js">void=null;</script>
<link rel="stylesheet" href="styles.css" type="text/css">
</head>
<body>


<div id="content">

<h1>yao</h1>

<div id="links">
<p><b>Links</b></p>
<a href="aosimul.html">Main page</a><br>
<ul class="linkpacked">
<li><a href="#features">Main Features</a>
<li><a href="#start">Where to start?</a>
</ul>
<a href="installation.html">Installation</a><br>
<a href="examples.html">Examples and Scripts</a><br>
<a href="performance.html">Performance</a><br>
<a href="data-structures.html">Data structures and parfiles</a><br>
<a href="feature-control.html">Controlling Features</a><br>
<a href="screenshots.html">Screenshots</a><br>
<a href="algorithms.html">Algorithms</a><br>
<a href="ytkcontrol.html">Yao tk dynamic control</a><br>
<a href="weblog.html">News/Weblog</a><br>
</div>


<h2>Introduction</h2>

These pages present information about <b>yao</b> version 3.0, a simulation tool for Adaptive optics (AO) systems.

<p>This package is loosely inherited from "aosimul.pro", an IDL set of routines that I wrote many years ago and have been put to use in a lot of places, but it is much more versatile and yet, faster. <b>Yao</b> is open source, although I have not yet bothered to put the legal license in there. You are welcome to use it, expand it and even distribute it, but please link back to this page, as I will be releasing updates regularly.


<a name="features"></a>
<h2>Main features</h2>
<b>Yao</b> is a Monte-Carlo AO simulation tool. It uses a number of custom developed functions to simulate the wavefront sensor (WFS), the deformable mirror (DM) and many other aspects of an AO loop. 
<h4 class="highlight">Highlights</h4>

<ul class="spaced">

<li><font class="highlight">Coded in <a href="ftp://ftp-icf.llnl.gov/pub/Yorick/doc/index.html">yorick</a></font>, a open source scripting language similar to IDL or mathlab (powerful and free!). The core, CPU intensive routines are coded in C and make use of vectorial libraries to speed up calculations.

<li><font class="highlight">Shack-Hartmann and Curvature WFS</font>, on or off axis, are supported

<li><font class="highlight">Stackarray</font> (piezostack), <font class="highlight">curvature</font> (bimorph), <font class="highlight">modal</font> (zernike) and <font class="highlight">Tip-Tilt deformable mirrors</font> are supported. The altitude of conjugation is adjustable. 

<li>An <font class="highlight">arbitrary number of WFSs and DMs</font> can be selected, with the possibility of mixing types. It is therefore possible (and easy) to simulate single DM systems, as well as single non-zero conjugate, GLAO and MCAO systems.

<li>It supports <font class="highlight">Natural and Laser Guide Stars</font> (or a mix).

<li>It supports <font class="highlight">photon and read-out noise</font>.

<li>It uses a multi-layered atmospheric model, with geometrical propagation only.

<li>The loop execution has been 
<font class="highlight">optimized for speed</font>: the critical routines have been coded in C. Yorick is thus used as a convenient "glue" between lower levels optimized C calls. Overall, this is rather efficient:  A simple 6x6 Shack-Hartmann system runs at up to 650 iterations per second on an apple dual 2GHz G5 (200 iterations/sec for a full diffraction propagation model). A 50x50 Shack-Hartmann system runs at about 3 iterations/s. A 188 curvature system runs at 25 iterations/s (see the <a href="performance.html">performance</a> page for more details).
<li>Straightforward scriptability to probe parameter domains
<li>"Toy" interface to change some of the system parameters <font class="highlight">while the loop is running</font> (new in v3.0). This provides an educational approach to Adaptive Optics (newbies can play with the parameters and immediately sees how the system reacts) and can also provides a quick way to investigate the stability conditions for a newly designed system, before entering more serious Monte-carlo simulations.

</ul>

<h4 class="highlight">The following other capabilities are supported:</h4>
<ul class="spaced">
<li>Partitioning of DMs and WFSs in independent subsystems
<li>2 methods for Shack-Hartmann:
<ol>
<li>Simple gradient average, no noise, very fast: This allow to do tests of the noiseless performance of a system, for quick performance evaluation of system dimensioning
<li>Full propagation, with subaperture image formation. Includes adjustable subaperture and pixel size, photon and read-out noise, bias and flat field errors, thresholding, convolution by a gaussian kernel and image elongation in the case of LGS
</ol>
<li>Separately adjustable integration time for each sensor
<li>Anisoplanatism modes for MCAO
<li>DM Hysteresis
<li>DM saturation
<li>Separate loop gain per DM
<li>Adjustable DM sensitivity (micron/volt)
<li>Adjustable subaperture and actuator validation thresholds
<li>Adjustable condition numbers for the interaction matrix inversion
<li>Circular pupil with central obstruction
<li>Adjustable multi-wavelength, multi-position performance estimate
<li>Adjustable frame delay (in integer unit of the quantum loop time)
<li>"Skip and reset" along the phase screens at adjustable interval, to more quickly reach statistically significant performance estimates
<li>Uplink tip-tilt correction for LGS
<li>Adjustable LGS Elongation
<li>Extrapolated actuators
<li>Centroid Gain optimization, using LGS dithering (only for LGS + Shack-Hartmann)
<li>Lots of internal variables are accessible from the outside of the program for debugging/implementation of new features
</ul>

<h4 class="highlight">Other remarks and shorcomings:</h4>
<ul class="spaced">
<li>I have made use of <font class="highlight">fast FFT external libraries</font> to significantly improve the speed of the aoloop core routines. <b>Yao</b> comes in two flavors: one uses the proprietary <font class="highlight">Apple vectorial libraries</font> (veclib), the other uses <font class="highlight">FFTW</font> (open source). The former obviously runs only on Apple hardware, while the later runs on almost everything (but requires that you install FFTW3, some instructions are provided).
<li>The set-up routines (aoinit) have not yet been optimized for speed, thus, in particular, inverting large matrices can take some time. This optimization may come in due time, if deemed necessary.
<li><font class="highlight">There is no GUI to configure the systems</font>. The parfile has to be edited manually, which in my view is not a big deal and actually allows for more compact &amp; clever parfiles, as yorick loops can be used to set repetitive variables.
<li>Some work has been done with pyramid WFS but no has not been maintained and does not work in the current version
<li>Scintillation is not supported, as it has been shown by many studies to be negligible at NIR wavelengths.
<li>Command matrices are up to now computed as least-square estimates. Implementation of minimum-variance or MAP should come shortly.
</ul>


<a name="start"></a>
<h2>Where to start?</h2>

Browse this site. Have a look at the <a href="examples.html">Example &amp; Scripts</a> and <a href="screenshots.html">Screenshots</a> pages. If you like what you see, go to the <a href="installation.html">Installation</a> page and follow the instructions.
<p>Once the package is installed, follow the <a href="examples.html">examples</a>, and then edit your own parfiles to modelize your system.

</div>
<p>
<a style="float:right;" href="http://jigsaw.w3.org/css-validator/">
  <img style="border:0;width:88px;height:31px"
       src="http://jigsaw.w3.org/css-validator/images/vcss" 
       alt="Valid CSS!">
</a>

<?
include_once "./acounter.php";
$ani_counter = new acounter();
echo $ani_counter->create_output("aosimul");
?>
<font style="vertical-align:super;">
loads since 24/05/2004. 
Page updated 9 April 2004.
</font>

</body>
</html>