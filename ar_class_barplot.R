#!/usr/bin/env Rscript
library(ggplot2)

argv <- commandArgs(TRUE)
inputfile <- argv[1]
output <- argv[2]
z<-read.table(inputfile,sep="\t",quote="",header=T)
names(z)<-c("Definition","Counts")
z<-z[order(z$Counts,decreasing=T),]
#only top 50 for plot
z<-head(z,50)
#z$Definition <- factor(z$Definition, levels=z$Definition[order(z$Counts,decreasing=T)])
tail(z)
label <- 'Antibacterial Resistance class and counts'

p <- ggplot(z,aes(Definition,Counts)) + geom_bar(aes(fill = Definition), stat="identity",position="dodge") + labs(title=label) +
  theme(legend.position = "none",legend.direction="horizontal", legend.title = element_blank(),
        axis.text.y  = element_text(hjust=1.0,colour="black",size=10),axis.text.x  = element_text(angle=0,colour="black",size=10),
        axis.title.y=element_text(hjust=-1,size=8), panel.background = element_blank(),axis.title.x=element_text(vjust=0),
        panel.border = element_rect(colour="black",fill=NA,size=1),
        panel.grid.minor = element_line(colour = "grey", linetype = "dotted", size=0.1),
        panel.grid.major = element_line(colour = "grey", linetype = "dotted", size=0.1)) +
  ylab("Number of Genes")+xlab("") + guides(fill = guide_legend(keywidth = 0.8,keyheight = 0.8)) + coord_flip()

outputfile <- paste(output, '.pdf', sep="")
ggsave(paste(outputfile,sep=""),p,device='pdf')
outputfile2 <- paste(output, '.png', sep="")
ggsave(paste(outputfile2,sep=""),p,device='png')
