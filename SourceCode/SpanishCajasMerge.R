#################
# Parse Spanish Cajas XBRL files 
# Christopher Gandrud
# 2 December 2013
#################

# Load packages
library(XML)
library(plyr)
library(reshape2)
library(DataCombine)
library(lubridate)

# Data gathered from: http://www.cajasdeahorros.es/#/PAG|estados
setwd('~/Desktop/Cajas/')

Files <- list.files()

Combined <- data.frame()

for (i in Files){
	# Convert to data frame
	Temp <- ldply(xmlToList(i), function(x) data.frame(x, stringsAsFactors = FALSE))

	# Create date variable value
	date <- unique(Temp$instant)
	date <- date[2]
  
  # Correct identifier numbering format issue for data before 2009
  if ("identifier" %in% names(Temp)){
    TempID <- subset(Temp, .id == "context")
    for(i in 1:nrow(TempID)){
      TempID$In[[i]] <- grepl("http", TempID$identifier[[i]])
    }
    TempID <- subset(TempID, In == FALSE)
    Temp <- FindReplace(data = Temp, Var = '.attrs', replaceData = TempID, 
                        from = '.attrs', to = 'identifier', exact = TRUE)
  }

	# Keep important variables and ids
	Temp <- Temp[, c('.attrs', '.id', 'text')]
	Temp <- subset(Temp, !is.na(text))

	# Drop attributes other than bank identifier
	Temp <- subset(Temp, .attrs != '-3')
	Temp <- subset(Temp, .attrs != 'uEUR')
  Temp <- subset(Temp, .attrs != 'u1')

	# Excract bank code
	Temp$.attrs <- gsub("cES", "", Temp$.attrs)
	Temp$.attrs <- gsub("-d2e2-1", "", Temp$.attrs)

	names(Temp) <- c('bank', 'variable', 'value')
	Temp$value <- as.numeric(Temp$value)

	# Cast
	TempCast <- dcast(Temp, bank ~ variable, value.var = "value", fun.aggregate = sum)

	# Add date
	TempCast$date <- date
	TempCast <- MoveFront(TempCast, Var = c('bank', 'date'))

	# Merge Together
	Combined <- rbind.fill(Combined, TempCast)

	# Remove temps
	rmExcept("Combined", message = FALSE)
}

# Clean Data
Combined$date <- ymd(Combined$date)
Combined <- Combined[order(Combined$bank, Combined$date), ]

write.csv(Combined, file = "~/Desktop/CajasCombined.csv")

#### Tests ###
CombinedSub <- Combined

CombinedSub$One <- 1
CombinedSub <- ddply(CombinedSub, .(date), transform, total = sum(One))
CountSub <- CombinedSub[!duplicated(CombinedSub[, 1]), ]

library(ggplot2)

ggplot(CountSub, aes(date, total)) + geom_line() + theme_bw()

ActivoMaterialActivosNoCorrientesVentaActivoPresentacion
NonCurrentAssetsAndDisposalGroupsHeldForSale
AjustesValoracion

ggplot(Combined, aes(date, AjustesValoracion, colour = bank)) + 
  geom_line() + theme_bw()
