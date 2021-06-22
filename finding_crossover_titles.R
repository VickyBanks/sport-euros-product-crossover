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

iplayer_titles<-
vb_euros_crossover %>%
  filter(products_used == '2_sport_iplayer') %>%
  select(audience_id)%>%
  left_join(vb_euros_iplayer, by = 'audience_id') %>%
  select(-age_group)%>%
  group_by(programme_title)%>%
  count()%>%
  rename(users = n)%>%
  rename(iplayer_title = programme_title)%>%
  arrange(desc(users)) %>% head(n=10)

sounds_titles<-
  vb_euros_crossover %>%
  filter(products_used == '2_sport_iplayer') %>%
  select(audience_id)%>%
  left_join(vb_euros_sounds, by = 'audience_id') %>%
  select(-age_group)%>%
  group_by(programme_title)%>%
  count()%>%
  rename(users = n)%>%
  rename(sounds_title = programme_title)%>%
  arrange(desc(users)) %>% head(n=10)

sport_titles<-
  vb_euros_crossover %>%
  filter(products_used == '2_sport_iplayer') %>%
  select(audience_id)%>%
  left_join(vb_euros_sport, by = 'audience_id') %>%
  select(-age_group)%>%
  group_by(programme_title)%>%
  count()%>%
  rename(users = n)%>%
  rename(sport_title = programme_title)%>%
  arrange(desc(users))%>% head(n=10)

rank %>%cbind(sport_titles) %>%cbind(iplayer_titles)%>%cbind(sounds_titles)
