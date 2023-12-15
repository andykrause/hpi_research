#***************************************************************************************************
#
#   Functions for cleaning King County Data
#
#***************************************************************************************************


kngBuildPinx <- function(X,                     # Dataset to use, including Major, Minor
                         condoComp = FALSE      # Is this a condoComp dataset?
){
  
  # If condoComp fix minor to 0000
  if(condoComp) {
    X <- as.data.frame(X)
    X$Minor <- '0000'
  }
  
  # convert names    
  oldNames <- colnames(X)
  newNames <- tolower(oldNames)
  colnames(X) <- newNames
  
  # ensure value is numeric
  X$major <- as.numeric(X$major)
  if(!condoComp) X$minor <- as.numeric(X$minor)
  
  # remove NA columns
  X <- X[!is.na(X$major),]
  if(!condoComp) X <- X[!is.na(X$minor),]
  
  # Remove those with invalid values
  X <- X[X$major < 1000000, ]
  if(!condoComp) X <- X[X$minor < 10000, ]
  
  # Add leading to major
  X$major <- addLeadZeros(X$major, maxChar=6)
  
  # Add leading to minor
  if(!condoComp) X$minor <- addLeadZeros(X$minor, maxChar=4)
  
  # Combine  
  X$pinx <- paste0("..", X$major, X$minor)
  
  # Reorder
  X <- X[ ,c("pinx", newNames)]
  colnames(X)[2:ncol(X)] <- oldNames
  
  # Return X
  return(X)
}

addLeadZeros <- function(xNbr, # Numbers to add 0s to
                         maxChar = 6 # Desired total length
)
{
  missZero <- maxChar - nchar(xNbr)
  xNbr <- paste0(unlist(as.character(lapply(missZero, leadZeroBuilder))),
                 xNbr)
  return(xNbr)
}

leadZeroBuilder <- function(x)
{
  if(length(x)==0){
    return(0)
  } else {
    gsub('x', '0', paste0(unlist(rep("x", x)), collapse=''))
  }
}


trimList=list(SaleReason=2:19,  
              SaleInstrument=c(0, 1, 4:28),
              SaleWarning=paste0(" ", c(1:2, 5:9, 11:14,
                                        18:23, 25, 27,
                                        31:33, 37, 39,
                                        43, 46, 48, 49,
                                        50:53, 59, 61,
                                        63, 64, 66),
                                 " "))

