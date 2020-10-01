
#################
# Load packages #
#################
library(lattice)
library(ggplot2)
library(sp) #for points.in.polygon
library(raster) #for pointDistance
library(tiff)
library(EBImage)
library(Gmedian)
#######################################################
# Morphological transformation and centroid distances #
#######################################################
## Read images and transform
# Read original images (cmd version)
args <- commandArgs(TRUE);
func=as.character(args[1]);
source(func); #source("../ML-rcode/image-segmentation-func.R")
dir=as.character(args[2]); #dir="/Users/mingyang/Workspace/2018-06-11-Ab_T_images/lines/RAL-40"
dirout=as.character(args[3]); #name="RAL-40"
cat("check dir: ",dir,"; dirout",dirout,"\n");

# Read original images (Rstudio version)
#rm(list=ls())
#source("image-segmentation-func.R")
#dir="../200-original-images/";dirout="./";

#########main here##############
tiffFiles <- list.files(path=dir,pattern="*jpg$", full.name=F)
print(tiffFiles);

n.images=length(tiffFiles);
images=tiffFiles;
#plot.ncol=2;

tiffFiles=paste(dir,images,sep='/');
allfiles=tiffFiles;

for(myi in 1:length(allfiles)){
  tiffFiles=list(allfiles[[myi]]);
  tiffList <- lapply(tiffFiles, readImage)
  
  # Resize to fit memory
  tiffRes <- lapply(tiffList, resFunc)
  rm(tiffList); invisible(gc()) # free memory space
  
  # quick check
  lapply(tiffRes, function(x){ cat(dim(x),"\n")})
  
  # Assign resized images RGB channels to data frames
  tiffOri <- lapply(tiffRes, RGBintoDF)
  
  # White TopHat morphological transform
  tiffTop <- lapply(tiffRes, function(x) wTopHat(x,y=5,z='diamond'))
  # Display example images
  #par(mfcol=c(plot.ncol,ceiling(n.images/plot.ncol)))
  #invisible(lapply(tiffRes[1:n.images], dispImg)) 
  #invisible(lapply(tiffTop[1:n.images], function(x) dispImgT(x, 0.99)))
  
  ## Threshold and centroids
  # Assign gray channel to data frame
  tiffG <- lapply(tiffTop, GintoDF)
  # Threshold to keep pixels with intensity > 0.99 quantile
  tiffThres <- lapply(tiffG, function(x) {x[x$G > quantile(x$G,0.99), ]})
  names(tiffThres) <- seq(1:length(tiffThres))
  
  cutoffs=c(0.8,0.3);
  for(cutoff in cutoffs){
    # Estimate images centroid
    centroids <- lapply(tiffThres, function(x) Weiszfeld(x[,1:2]))
    
    # Plot retained pixels
    thresXY <- lapply(tiffThres, function(x) x[,1:2, drop=FALSE])
    #par(mar=c(2,2,2,0.5), mfcol=c(plot.ncol,ceiling(n.images/plot.ncol)))
    #for (i in 1:n.images) {
    #  dim(thresXY[[1]]);
    #  plot(thresXY[[i]],main=images[i])
    #  par(new=T)
    #  points(centroids[[i]]$median, col="red", pch=19)
    #}
    
    ## Distances to centroide,calculate distances to centroid
    distCent <- list()
    for (i in 1:length(thresXY)) {
      pdist <- pointDistance(p1=thresXY[[i]],
                             p2=centroids[[i]]$median,
                             lonlat=F)
      # Mark distances > 0.8 quantile, as they belong to
      # points outside the eye boundary in their majority
      #pLogic <- pdist < quantile(pdist, 0.80)
      pLogic <- pdist < quantile(pdist, cutoff);
      pp <- cbind(distCent = pdist, selected = pLogic)
      distCent[[i]] <- pp
    }
    
    # Plot example histograms
    #par(mar=c(2,2,2,0.8),  mfcol=c(plot.ncol,ceiling(n.images/plot.ncol)))
    #for (i in 1:n.images) {
    #  hist(distCent[[i]][,1],main=images[i])
    #  abline(v=quantile(distCent[[i]][,1], cutoff), col="red",lty="dashed", lwd=2)
    #}
    # Join thresholded and distances lists
    thresDist <- mapply(cbind, tiffThres, distCent, SIMPLIFY = FALSE)
    # retain points with distance < quantile cutoff 0.8
    distSelect <- lapply(thresDist, function(x) x[x$selected == 1, ]);
    
    # Plot examples (black clouds with blue roi overlay)
    #plotThres <- list()
    #for (i in 1:n.images) {
    #  p <- ggplot(data=thresDist[[i]], aes(x=x, y=y,color=selected)) +
    #    geom_point(show.legend = FALSE) + ggtitle(images[i]) + plotTheme()
    #  plotThres[[i]] <- p
    #}
    #tmp=ceiling(n.images/plot.ncol);
    #lay <- matrix(1:(tmp*plot.ncol),ncol=plot.ncol)
    #gridExtra::grid.arrange(grobs=plotThres, layout_matrix = lay)     
    
    tiffThres <- lapply(thresDist,function(x) x[x$selected == 1, 1:3]);
  }
  
  ## Subset and confidence ellipse and Add ellipse to plot 
  ellPlots <- lapply(distSelect, function(x) ellPlot(x,0.90))
  # Extract components
  build <- lapply(ellPlots, function(x) ggplot_build(x)$data)
  ells <- lapply(build, function(x) x[[2]])
  # Select original image points inside ellipse
  origpixList <- list()
  for (i in 1:length(thresXY)) {
    imgOri <- tiffOri[[i]]
    ell <- ells[[i]]
    origEll <- data.frame(imgOri[,1:5],
                          in.ell = as.logical(point.in.polygon(imgOri$x,imgOri$y, ell$x, ell$y)))
    origPix <- origEll[origEll$in.ell==TRUE,]
    origpixList[[i]] <- origPix
  }
  
  ## Create image from final ROI
  roisImg <- lapply(origpixList, roitoImg)
  #display(roisImg[[4]]); #check image
  
  for( i in 1:length(roisImg)){
    #pic=readImage("group13.Day28.441C_4-0.jpg");
    pic=roisImg[[i]];
    #hist(pic);
    #grid()
    
    y = equalize(pic)
    #hist(y)
    #grid()
    #display(y, title='Equalized Grayscale Image')
    
    grayimage<-channel(y,"grey")
    #display(grayimage)
    nmask = thresh(grayimage, w=5, h=5, offset=0.02); #display(nmask)
    nmask = opening(nmask, makeBrush(3, shape='disc')); #display(nmask)
    nmask = fillHull(nmask); #display(nmask)
    nmask = bwlabel(nmask)
    cat("Number of omma=",max(nmask),"\n");
    
    fts = computeFeatures.moment(nmask)
    
    pdf(paste(dirout,"/",images[myi],"-roi.pdf",sep=''));
    par(mfrow=c(1,2));
    display(pic,"raster")
    display(nmask,"raster");
    text(fts[,"m.cx"], fts[,"m.cy"], 
         labels=seq_len(nrow(fts)), col="red", cex=0.8)
    
    fts2 <- computeFeatures.shape(nmask)
    dev.off();
    out1.name=paste(dirout,"/",images[myi],"-coord.txt",sep='');
    out2.name=paste(dirout,"/",images[myi],"-area.txt",sep='');
    write.table(fts,file=out1.name,quote=F,row.names = F);
    write.table(fts2,file=out2.name,quote=F,row.names = F);
    
  }
}
