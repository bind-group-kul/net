Eye movement artifact removal plugin for EEGLAB

This plugin has been designed to subtract linear components associated
with eye blinks, and horizontal and vertical eye movements from EEG
according to the methods described in

@article{parra2005,
      author = {Lucas C. Parra and Clay D. Spence and Adam Gerson
                and Paul Sajda},
      title = {Recipes for the Linear Analysis of {EEG}},
      journal = {{NeuroImage}},
      year = {in revision}}

The interface for pop_eyesubtract.m requires as input, the number of
the EEGLAB data set containing the data collected during the
eye movement artifact removal experiment (described below) as well
as the number of the EEGLAB data set containing the data from
which eye movement components are to be subtracted.  The plugin will
create a new dataset containing this artifact-free data.  The 
eye movement component weights (V) and the associated forward 
models (A) will be stored in the icaweights and icawinv variables 
of the eye movement artifact removal experiment dataset.

Note that the new dataset will be rank deficient since three
eye movement components have been removed.  Further analysis
should be performed on a subspace of the data as described in
cite{parra2005}.

Eye movement artifact removal experiment

Experiments for subtracting eye movement related components from EEG
have been provided for the following software:

E-Prime
Experiment script: eyecalibration.es
Psychology Software Tools, Inc., Pittsburgh, PA
http://www.pstnet.com 

Presentation
Experiment scripts: eyecalibration.pcl, eyecalibration.sce
Neurobehavioral Systems, Albany, CA
http://nbs.neuro-bs.com

During these experiments, subjects are instructed to blink repeatedly,
then follow a fixation cross from left to right and top to bottom
of the screen.  It is important that the subject blinks in
``natural'' intervals.  The timing of the eye movements are 
recorded on the event channel.

The data obtained from this experiment can be used to find
eye movement related linear components and subtract them
from a data set of interest using the eye subtraction plugin
for EEGLAB.

An example of a dataset collected using a 72 channel BioSemi
system using the Presentation script is available:
http://liinc.bme.columbia.edu/downloads
This data has been rereferences to average mastiods, channels
71 and 72.
