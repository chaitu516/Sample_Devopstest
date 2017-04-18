options(skip=1,DIRECT=TRUE, ERRORS=50)
LOAD DATA
INFILE 'E:\app\chaitanya.bandi\product\11.2.0\dbhome_1\INPUTfiles\SampleData.csv'
TRUNCATE INTO TABLE sqlldr_test
FIELDS TERMINATED BY ',' 
optionally enclosed BY '"' 
trailing nullcols
 (
c1,c2,c3,c4
)

