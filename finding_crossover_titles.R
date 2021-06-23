library(tidyverse)
library(RPostgres)
## redshift setup 
credentials_path <- "~/Documents/Projects/DS/"
source(file.path(credentials_path, "redshift_creds.R"))

dbname="redshiftdb"
host='localhost'
port='5439'
user=redshift_username
password=redshift_password

conn <- dbConnect(RPostgres::Postgres(),  
                  host = host,
                  port = port,
                  user = user,
                  password = password,
                  dbname = dbname,
                  sslmode='require')

rm(redshift_username, user, redshift_password, password)


####### get data
vb_euros_crossover<- dbGetQuery(conn, "SELECT * FROM central_insights_sandbox.vb_euros_crossover;")
vb_euros_iplayer<- dbGetQuery(conn, "SELECT * FROM central_insights_sandbox.vb_euros_iplayer;")
vb_euros_sounds<- dbGetQuery(conn, "SELECT * FROM central_insights_sandbox.vb_euros_sounds;")
vb_euros_sport<- dbGetQuery(conn, "SELECT * FROM central_insights_sandbox.vb_euros_sport;")

product_groups<-vb_euros_crossover%>%select(products_used) %>%distinct()%>%arrange(products_used)
product_groups 

rank<- data.frame(rank = c(1,2,3,4,5,6,7,8,9,10))
#make empty DF
top_content <- data.frame(
  products_user = character(),
  rank = double(),
  iplayer_title  = character(),
  iplayer_users = integer(),
  sounds_title  = character(),
  sounds_users = integer(),
  sport_title  = character(),
  sport_users = integer()
)

for(row in 1:nrow(product_groups)){
##find top titles
iplayer_titles <-
  vb_euros_crossover %>%
  filter(products_used == product_groups[row,]) %>%
  select(audience_id) %>%
  left_join(vb_euros_iplayer, by = 'audience_id') %>%
  select(-age_group) %>%
  group_by(programme_title) %>%
  count() %>%
  rename(iplayer_users = n) %>%
  rename(iplayer_title = programme_title) %>%
  arrange(desc(iplayer_users)) %>% 
  head(n = 10) %>%
  mutate(products_used = product_groups[row,]) %>%
  cbind(rank)%>%
  select(products_used, rank, iplayer_title, iplayer_users)



sounds_titles<-
  vb_euros_crossover %>%
  filter(products_used == product_groups[row,]) %>%
  select(audience_id)%>%
  left_join(vb_euros_sounds, by = 'audience_id') %>%
  select(-age_group)%>%
  group_by(programme_title)%>%
  count()%>%
  rename(sounds_users = n)%>%
  rename(sounds_title = programme_title)%>%
  arrange(desc(sounds_users)) %>% head(n=10)

sport_titles<-
  vb_euros_crossover %>%
  filter(products_used == product_groups[row,]) %>%
  select(audience_id)%>%
  left_join(vb_euros_sport, by = 'audience_id') %>%
  select(-age_group)%>%
  group_by(programme_title)%>%
  count()%>%
  rename(sport_users = n)%>%
  rename(sport_title = programme_title)%>%
  arrange(desc(sport_users))%>% head(n=10)

group_combined<-iplayer_titles %>% cbind(sounds_titles)%>%cbind(sport_titles)

## If there are no titles because users didn't visit, remove the user count as it's confusing
group_combined$iplayer_users[is.na(group_combined$iplayer_title)] <- NA
group_combined$sounds_users[is.na(group_combined$sounds_title)] <- NA
group_combined$sport_users[is.na(group_combined$sport_title)] <- NA

top_content<-top_content %>%rbind(group_combined)
}
top_content %>%View()

getwd()
write.csv(top_content, "top_content_items.csv", row.names = FALSE)


### re-cut the data to make comparisons easier






