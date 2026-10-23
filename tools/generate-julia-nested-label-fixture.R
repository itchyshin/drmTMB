# Native labels and evaluated columns; no model fit or GPL implementation copy.
args<-commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==1L,!file.exists(args[1]))
dat<-data.frame(x=seq(.2,1.6,length.out=8),z=seq(-.7,.7,length.out=8))
expressions<-c('log1p(1 + I(x^2))','log1p((1 + I(x^2))/2)',
 'sqrt((I(x^2) + 1)^2)','log1p(I(x^2) - (x - 2))',
 'log1p(I(x^2)/(x + 2))','log1p((I(x^2)))',
 'sqrt(((I(x^2) + 1)))','log1p((I(x^2) + 1)/(I(z^2) + 2))',
 'sqrt((I(x^2) + 1)^2 + I(z^2))','exp(I(x^2)/(z + 4))')
out<-do.call(rbind,lapply(expressions,function(expr){
 X<-model.matrix(as.formula(paste('~',expr)),dat)
 stopifnot(ncol(X)==2L,all(is.finite(X)))
 data.frame(expression=expr,expected=colnames(X)[2],
  as.list(setNames(sprintf('%.17g',X[,2]),paste0('v',1:8))))
}))
write.table(out,args[1],sep='\t',quote=FALSE,row.names=FALSE)
cat('NATIVE_NESTED_LABELS',nrow(out),'R',as.character(getRversion()),
 'x=seq(.2,1.6,length.out=8);z=seq(-.7,.7,length.out=8)\n')
