# Native labels and evaluated columns; no model fit or GPL implementation copy.
args<-commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==1L,!file.exists(args[1]))
dat<-data.frame(x=seq(.2,1.6,length.out=8),z=seq(-.7,.7,length.out=8))
expressions<-c('ifelse(x > 0.8, x, 0)', 'ifelse(z <= 0, x, z)',
 'ifelse(z != 0, log1p(x), 0)', 'ifelse((z > 0) & (x < 1), x, 0)',
 'ifelse(!(z > 0), x, 0)', 'ifelse((z > 0) & (x < 1.5), x, 0)',
 'ifelse((z < -0.3) | (x > 1.2), x, z)', 'ifelse(z >= 0, x, z)',
 'ifelse(x == 1, x, z)', 'ifelse(x != 1, x, z)',
 'ifelse(!(z > 0) | (x > 1.5), x, z)', 'ifelse(!(!(z > 0)), x, z)',
 'exp(ifelse(!(z > 0), x, z))')
out<-do.call(rbind,lapply(expressions,function(expr){
 X<-model.matrix(as.formula(paste('~',expr)),dat)
 stopifnot(ncol(X)==2L,all(is.finite(X)))
 data.frame(expression=expr,expected=colnames(X)[2],
  as.list(setNames(sprintf('%.17g',X[,2]),paste0('v',1:8))))
}))
write.table(out,args[1],sep='\t',quote=FALSE,row.names=FALSE)
cat('NATIVE_CONDITIONAL_LABELS',nrow(out),'R',as.character(getRversion()),
 'x=seq(.2,1.6,length.out=8);z=seq(-.7,.7,length.out=8)\n')
