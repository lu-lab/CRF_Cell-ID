# CRF Cell ID

<img src = "extra/readme_img_v2.jpg" width=45% align="right">

This software/tools were developed for automatically detecting cells in dense brain images, annotating biological identities, visualizing results, and building new atlases using ground-truth annotations. In contrast to popular registration based methods, `CRF_Cell_ID` formulates a structured prediction problem that is solved with second-order Conditional Random Fields model. Thus `CRF_Cell_ID` finds optimal labels for all cells that are most consistent with prior knowledge in terms of maintaining second-order features such as positional relationships. `CRF_Cell_ID` provides a computationally scalable method for building atlases from annotated data.

To learn about details of the method, please read the <a href="https://www.biorxiv.org/content/10.1101/2020.03.10.986356v1">paper</a>. A detailed guide on using the framework is __coming soon__

This repository contains - 
1. Code for predicting identities in new datasets
2. Code for building new atlas based on ground-truth annotated datasets
3. Raw datasets used in the paper, ground-truth annotations, and codes for reproducing results

<img src = "extra/video1_gif.gif" width=100% align="center">
	
	
	
  

  
