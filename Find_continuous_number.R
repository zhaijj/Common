#Find continuous numbers
findContinuous <- function(inputVec){
  Breaks <- c(0, which(diff(inputVec) != 1), length(inputVec)) 
  res <- sapply(seq(length(Breaks) - 1), 
                function(i) inputVec[(Breaks[i] + 1):Breaks[i+1]]) 
  res
}
