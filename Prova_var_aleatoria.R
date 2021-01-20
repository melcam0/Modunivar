
x<-seq(-5, 5,by = 0.1)
df<-cbind.data.frame(x=x,y=dnorm(x,mean=0,sd=1))
gr<-ggplot() +theme_classic()+
  geom_line(data = df,mapping = aes(x=x,y=y))+
  ylab("densità")+xlab("x")+xlim(-5,5)+
  geom_hline(yintercept = 0)

gr

x<-rnorm(n = 1);y<-rep(0,length(x))
df_p<-cbind.data.frame(x,y)

gr+
  geom_point(df_p, mapping=aes(x = x,y=y))
  


library(ggplot2)
ggplot()+theme_classic()+
  geom_point(df, mapping=aes(x = x,y=y))+xlim(-5,5)


x<-rnorm(n = 1000);y<-rep(0,length(x))
df_p<-cbind.data.frame(x,y)
ggplot()+theme_classic()+
  geom_histogram(df_p, mapping=aes(x = x,y = ..density..),fill="blue",col="white",
                 
                  #binwidth =(max(df$x)-min(df$x))/sqrt(nrow(df))
                 binwidth =0.1
  )+
  xlab('x')+ylab("densità")+xlim(-5,5)

### notare che essendo base 0.1 la probalitità=densità*10
