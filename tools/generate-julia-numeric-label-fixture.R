# Generated R outputs may be used as a Julia parity fixture; no R source is
# copied into the MIT engine. Pure label generation: no model fitting.
args <- commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==1L,!file.exists(args[1]))
options(scipen=0)
values <- unique(c(0,1,-1,10000,100000,100001,123456.789,1000000.1,
  1e-3,1e-4,1.234567890123456e-7,
  outer(c(-9.87654321098765,-1.23456789012345,1,1.23456789012345,9.87654321098765),
        10^seq(-300,300,by=10)),
  .Machine$double.xmin,.Machine$double.xmax))
values <- values[is.finite(values)]
out <- data.frame(input=sprintf('%.17g',values),
  deparse=vapply(values,function(x)deparse(x,width.cutoff=500),''),
  factor=as.character(values),stringsAsFactors=FALSE)
write.table(out,args[1],sep='\t',quote=FALSE,row.names=FALSE)
cat('NATIVE_NUMERIC_LABELS',nrow(out),'R',as.character(getRversion()),'scipen',getOption('scipen'),'\n')
