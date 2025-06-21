
clear
set more off
*set maxvar 32767, perm

********************************************************************************
**************************** Define folder locations ***************************
********************************************************************************
global path_general "G:\.shortcut-targets-by-id\1y48eK40cpzc62J3q6u-5ELnS_e6_SGOF\BGA Folder"

global path_Do "$path_general\02. Do\01. UCSD"
global path_Data "$path_general\01. Data\01. UCSD"

global path_Tables "$path_general\04. Output\01. UCSD\03-17-2025\Tables"
global path_Figures "$path_general\04. Output\01. UCSD\03-17-2025\Figures"


global path_Draft_Tables  "$path_general\09. Draft\1. UCSD\Tables"
global path_Draft_Figures "$path_general\09. Draft\1. UCSD\Figures"

exit

* XX. Raw data -----------------------------------------------------------------// Raw data
do "$path_Do\Genetic_Education_UCSD_RawData.do"										


* XX. Prepare data -------------------------------------------------------------// Prepare data
*do "$path_Do\Genetic_Education_UCSD_PrepareData.do"						


* XX. Explore data -------------------------------------------------------------// Explore data
*do "$path_Do\Genetic_Education_UCSDx`_ExploreData.do"						


