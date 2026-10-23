# Native labels and evaluated columns; no model fit or GPL implementation copy.
args<-commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==1L,!file.exists(args[1]))
dat<-data.frame(x=seq(.2,1.6,length.out=8),z=seq(-.7,.7,length.out=8))
expressions<-c('exp((1 + scale(x))/2)', 'sqrt((scale(x) + 2)^2)',
 'log1p(scale(x)/(z + 4))', 'exp((scale(x)))',
 'exp(scale(x) - (z - 2))', 'exp((scale(x) + I(z^2))/2)',
 'sin((x + z)/2)', 'exp((x))', 'log1p((x + 1)/2)',
 'exp(1e-7 * x)', 'exp(-(x + 1))', 'exp((I (x^2) + 1)/2)')
out<-do.call(rbind,lapply(expressions,function(expr){
 X<-model.matrix(as.formula(paste('~',expr)),dat)
 stopifnot(ncol(X)==2L,all(is.finite(X)))
 data.frame(expression=expr,expected=colnames(X)[2],
  as.list(setNames(sprintf('%.17g',X[,2]),paste0('v',1:8))))
}))
write.table(out,args[1],sep='\t',quote=FALSE,row.names=FALSE)
cat('NATIVE_SCALAR_LABELS',nrow(out),'R',as.character(getRversion()),
 'x=seq(.2,1.6,length.out=8);z=seq(-.7,.7,length.out=8)\n')
