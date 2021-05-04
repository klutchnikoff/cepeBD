install.packages("mongolite")
library(mongolite)
library(jsonlite)
library(tidyverse)

m <- mongo(
  collection = "klutchnikoff",
  db = "test",
  url = "mongodb://localhost",
  verbose = FALSE,
  options = ssl_options()
)

m2 <- mongo(
  collection = "test2",
  db = "test",
  url = "mongodb://localhost",
  verbose = FALSE,
  options = ssl_options()
)

m2$count()

m$drop()
m$insert(fromJSON("https://ringsdb.com/api/public/cards"))
m$count()

m$insert(list(name="Luke Skywalker", outlier=TRUE))
m$count()


m$find() %>% names()

m$find(query='{"type_name": "Contract"}',
       fields='{"_id": 0, "pack_name": 1, "name": 1, "illustrator": 1}')

m$find(query='{"outlier": {"$exists": true} }',
       fields='{"_id": 0, "name": 1}')

m$count(query = 
'{"$and": [
{"pack_name": "Core Set"},
{"type_name": {"$in": ["Hero", "Contract"]}}
]}')

m$find(query = 
          '{"$and": [
              {"pack_name": "Core Set"},
              {"type_name": {"$in": ["Hero", "Contract"]}}
            ]}') %>% nrow()


View(m$find() %>% head(3))

###### 1

# méthode dplyr
m$find() %>% 
  filter(type_name == "Hero") %>% 
  group_by(sphere_name) %>% 
  summarise(count = n()) %>% 
  arrange(desc(count))

m$aggregate('[
            {"$match": {"type_name": "Hero"}},
            {"$group": {"_id": "$sphere_name",
                        "count": {"$sum": 1}}}
]')

###### 2

# méthode dplyr
m$find() %>% 
  filter(type_name == "Hero") %>% 
  group_by(sphere_name) %>% 
  summarise(length = mean(str_length(text))) %>% 
  arrange(desc(length))

m$aggregate('[
            {"$match": {"type_name": "Hero"}},
            {"$group": {"_id": "$sphere_name",
                        "length": {"$avg": {"$strLenCP": "$text"}}}},
            {"$sort": {"length": -1}}
]')

# m$aggregate('[
#             {"$match": {"type_name": "Hero"}},
#             {"$project": {"longueur" : {"$strLenCP": "$text"}}},
#             {"$group": {"_id": "$sphere_name",
#                         "length": {"$avg": "$longueur"}}},
#             {"$sort": {"length": -1}}
# ]')

######## table de cont.

df <- m$aggregate('[
            {"$group": {"_id": {"sp": "$sphere_name", "tp": "$type_name"},
                        "count": {"$sum": 1}}}
]') %>% 
  mutate(sp = `_id` %>% pluck(1),
         tp = `_id` %>% pluck(2)) %>% 
  select(-`_id`)
df %>% pivot_wider(names_from = sp, values_from = count)
