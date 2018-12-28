library(cowplot)
sp <- ggplot(mpg, aes(x = cty, y = hwy, colour = factor(cyl)))+ 
  geom_point(size=2.5)
sp
# Bar plot
bp <- ggplot(diamonds, aes(clarity, fill = cut)) +
  geom_bar() +
  theme(axis.text.x = element_text(angle=70, vjust=0.5))
bp
plot_grid(sp, bp, sp, bp, labels=c("A", "B", "C", "D"), ncol = 2, nrow = 2)
