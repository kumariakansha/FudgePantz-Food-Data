#Create databse foodwine and use the same database and drop if already exists

DROP database IF EXISTS foodwine;
create database foodwine;
use foodwine;

#drop all the tables if they already exists


#dropping all the child tables first as they have foreign key and would violate the foreign key constraint if parent key is deleted first
DROP TABLE IF EXISTS beverage_nationality_look_up;
DROP TABLE IF EXISTS ing_tags_look_up;
DROP TABLE IF EXISTS bev_pair_look_up;
DROP TABLE IF EXISTS product_ingredient_look_up;

#Drop all the temporary tables that was used for importing if already existed.
DROP TABLE IF EXISTS temp_tags;                   
DROP TABLE IF EXISTS  bev ;
DROP TABLE IF EXISTS desert_dump ;
DROP TABLE IF EXISTS pizza_Ing;
DROP TABLE IF EXISTS product_ingredient_dump;

#dropping the parent tables from which foreign keys of child tables are referenced
DROP TABLE IF EXISTS Nationality;
DROP TABLE IF EXISTS Product ;
DROP TABLE IF EXISTS Ingredients ;
DROP TABLE IF EXISTS tags;

#Dropping all the views if already existed
DROP VIEW IF EXISTS Vegan_Dishes;
DROP VIEW IF EXISTS Taste_Type;
DROP VIEW IF EXISTS Beverage_Pair_Product;
DROP VIEW IF EXISTS Beverage_Type;
DROP VIEW IF EXISTS Gluten_Dishes;
DROP VIEW IF EXISTS EXP_BEV_COUNTRY;
DROP VIEW IF EXISTS Desert_Type;
DROP VIEW IF EXISTS Cuisine;


#Creating all the Tables.

#creating temporary tables to  import and dump the data from the tsv files to sql to have a table format

create temporary table bev (Bev varchar(255), Nat varchar(255) , Pair varchar(500));
create temporary table desert_dump (des varchar(255), ing varchar(500));
create temporary table pizza_Ing (Ingrdnt varchar(255), Category varchar(255) , Pair varchar(500),Before_val varchar(255),after varchar(255));
create temporary table product_ingredient_dump (Product varchar(255), Ing varchar(500),Category varchar(255));
create temporary table temp_tags (tag varchar(255));

#creating Base tables
create table Nationality(Nationality varchar(255), Nat_ID integer(10) AUTO_INCREMENT , PRIMARY KEY(Nat_ID)) ENGINE=INNODB;
create  table Ingredients( Ingredient varchar(300),ING_ID integer(10) AUTO_INCREMENT , PRIMARY KEY(ING_ID,Ingredient)) ENGINE=INNODB;
create table Product(Product_ID integer(10) AUTO_INCREMENT,product_name varchar(255),product_category varchar(255),PRIMARY KEY(Product_id),Price$ integer(10))ENGINE=INNODB;
create table tags(tag_id integer(10) AUTO_INCREMENT,tag varchar(255),PRIMARY KEY(tag_id))ENGINE=INNODB;

#creating Look-up/mapping tables.
create table Ing_tags_look_up( Ingrdnt varchar(255), Category varchar(255), Pair varchar(255),Tag_ID integer(10), Ing_ID integer(10),FOREIGN KEY (Tag_ID) REFERENCES  tags(tag_id) ,FOREIGN KEY (Ing_ID) REFERENCES  ingredients(ING_ID));


create  table bev_pair_look_up(Product varchar(300),Pair varchar(300),Product_ID integer(10),tag_id integer(10), CONSTRAINT f_p FOREIGN KEY (Product_ID) REFERENCES Product(Product_ID) ,FOREIGN KEY (tag_id) REFERENCES tags(tag_id) ) ENGINE=INNODB;

create  table Beverage_Nationality_look_up(Product varchar(300),Nat varchar(255),Nat_ID integer(10) , Product_ID  integer(10) ,FOREIGN KEY f_n(Nat_ID) REFERENCES Nationality (Nat_ID),FOREIGN KEY f_p(Product_ID) REFERENCES Product(Product_ID) ) ENGINE=INNODB;

create table product_ingredient_look_up(Product varchar(255), Ing varchar(500),Product_ID integer(10),Ing_ID integer(10),FOREIGN KEY (Product_ID) REFERENCES  Product(Product_ID) ,FOREIGN KEY (Ing_ID) REFERENCES  Ingredients(ING_ID) );
ALTER TABLE product_ingredient_look_up AUTO_INCREMENT=1001;



#Setting Auto-Increment counter's Initial position for all tables.
ALTER TABLE Nationality AUTO_INCREMENT=1001;
ALTER TABLE Product AUTO_INCREMENT=1001;
ALTER TABLE tags AUTO_INCREMENT=1001;
ALTER TABLE Ingredients AUTO_INCREMENT=1001;
ALTER TABLE bev_pair_look_up AUTO_INCREMENT=1001;
ALTER TABLE Ing_tags_look_up AUTO_INCREMENT=1001;
ALTER TABLE Beverage_Nationality_look_up AUTO_INCREMENT=1001;
ALTER TABLE product_ingredient_look_up AUTO_INCREMENT=1001;



#LOADING DATA FROM TSV IN TEMPORARY TABLES
#Loading the data from the beverages.txt into bev temporary tables.
LOAD DATA LOCAL INFILE 'beverages.txt' INTO TABLE  bev
 character set latin1
 FIELDS TERMINATED BY '\t' ENCLOSED BY ''
LINES TERMINATED BY '\n'  IGNORE 1 LINES;

#Loading the data from the deserts.txt into bev temporary tables.
LOAD DATA LOCAL INFILE 'deserts.txt' INTO TABLE  desert_dump
 character set latin1
 FIELDS TERMINATED BY '\t' ENCLOSED BY ''
LINES TERMINATED BY '\n'  IGNORE 1 LINES;

#Loading the data from the pizza.txt into bev temporary tables.
LOAD DATA LOCAL INFILE 'pizza.txt' INTO TABLE  pizza_Ing
 character set latin1
 FIELDS TERMINATED BY '\t' ENCLOSED BY ''
LINES TERMINATED BY '\n'  IGNORE 1 LINES;

#loading the products and their ingredient details in the temporary tables.
LOAD DATA LOCAL INFILE 'products.txt' INTO TABLE  product_ingredient_dump
 character set latin1
 FIELDS TERMINATED BY '\t' ENCLOSED BY ''
LINES TERMINATED BY '\n'  IGNORE 1 LINES;

#loading preprcessed tag data in temp_tags table
insert into temp_tags(tag) select distinct SUBSTRING_INDEX(SUBSTRING_INDEX(bev.Pair, ',', numbers.n), ',', -1)
from
  (select 1 n union all
   select 2 union all select 3 union all
   select 4 union all select 5 union all select 6 union all select 7 union all select 8 union all select 9 union all select 10 union all select 11 union all select 12) numbers INNER JOIN bev
  on CHAR_LENGTH(bev.Pair) 
     -CHAR_LENGTH(REPLACE(bev.Pair, ',', ''))>=numbers.n-1
      union
select  distinct SUBSTRING_INDEX(SUBSTRING_INDEX(pizza_Ing.Pair, ',', numbers.n), ',', -1)
from
  (select 1 n union all
   select 2 union all select 3 union all
   select 4 union all select 5 union all select 6 union all select 7 union all select 8 union all select 9 union all select 10 union all select 11 union all select 12) numbers INNER JOIN pizza_Ing
  on CHAR_LENGTH(pizza_Ing.Pair) 
     -CHAR_LENGTH(REPLACE(pizza_Ing.Pair, ',', ''))>=numbers.n-1 ;
      
update temp_tags
set tag=REPLACE(tag,'"','');
update temp_tags
set tag= REPLACE(tag,' ','');



#Inserting into base tables 
#SUBSTRING_INDEX function which searches for ',' value and terminate to new row whenever encountered anf then comma is stripped off and the result is passed to outer SUBSTRING function which works as loop to search all the ',' present in the substring.
 #insertng the values into nationality tables from the dump table bev 
insert into Nationality (Nationality) select distinct SUBSTRING_INDEX(SUBSTRING_INDEX(bev.Nat, ',', numbers.n), ',', -1) Nationality
from
  (select 1 n union all
   select 2 union all select 3 union all
   select 4 union all select 5) numbers INNER JOIN bev
  on CHAR_LENGTH(bev.Nat) 
     -CHAR_LENGTH(REPLACE(bev.Nat, ',', ''))>=numbers.n-1 
      
  order by
   n;
#updating the Nationality table for stripping off '"' and blank spaces from the Nationality column 
update Nationality
set Nationality = REPLACE(Nationality,'"','');
update Nationality 
set Nationality = REPLACE(Nationality,' ','');


#inserting the values in the product table with product name and product category.
insert into Product(product_name,product_category)  select des,'desert' from desert_dump;
insert into Product(product_name,product_category)  select Bev,'Beverage' from bev;
insert into Product(product_name)  select Product from product_ingredient_look_up_dump;
update Product
set product_category= 'Salad' where product_name like '%Salad%';
update Product
set product_category= 'Sandwich' where product_name like '%Sandwich%';
update Product
set product_category= 'Pizza' where product_category IS NULL;
Update Product 
set Price$= rand(10)+length(product_name);
  

#inserting the Ingredient from deserts dump 
insert into Ingredients(Ingredient) select  distinct SUBSTRING_INDEX(SUBSTRING_INDEX(desert_dump.ing, ',', numbers.n), ',', -1) 
from
  (select 1 n union all
   select 2 union all select 3 union all
   select 4 union all select 5) numbers INNER JOIN desert_dump
  on CHAR_LENGTH(desert_dump.ing) 
     -CHAR_LENGTH(REPLACE(desert_dump.ing, ',', ''))>=numbers.n-1 
   union 
select  REPLACE(Ingrdnt,' ','') from pizza_Ing;
update Ingredients
set Ingredient = REPLACE(Ingredient,'"','');
update Ingredients
set Ingredient = REPLACE(Ingredient,' ','');  


#Tags table
insert into tags(tag) select distinct tag from temp_tags;



#Inserting into look up tables.
insert into bev_pair_look_up(Product,Pair) select  distinct bev.Bev,SUBSTRING_INDEX(SUBSTRING_INDEX(bev.Pair, ',', numbers.n), ',', -1) Pair
from
  (select 1 n union all
   select 2 union all select 3 union all
   select 4 union all select 5) numbers INNER JOIN bev
  on CHAR_LENGTH(bev.Pair) 
     -CHAR_LENGTH(REPLACE(bev.Pair, ',', ''))>=numbers.n-1 
      
  order by
  Bev, n;
update bev_pair_look_up
set Pair= REPLACE(Pair,'"','');
update bev_pair_look_up
set Pair= REPLACE(Pair,' ','');
UPDATE bev_pair_look_up dest, (SELECT * FROM Product) src 
  SET dest.Product_ID = src.Product_ID where dest.Product=src.product_name ;
UPDATE bev_pair_look_up dest, (SELECT * FROM tags) src 
  SET dest.tag_id = src.tag_id where dest.pair=src.tag ;




#Inserting into the table that is storing restriction for every ingredient where pair id is a foreign key coming from tag.
Insert into  Ing_tags_look_up(Ingrdnt,Category,Pair) select distinct Ingrdnt,Category,SUBSTRING_INDEX(SUBSTRING_INDEX(pizza_Ing.Pair, ',', numbers.n), ',', -1) 
from
  (select 1 n union all
   select 2 union all select 3 union all
   select 4 union all select 5) numbers INNER JOIN pizza_Ing
  on CHAR_LENGTH(pizza_Ing.Pair) 
     -CHAR_LENGTH(REPLACE(pizza_Ing.Pair, ',', ''))>=numbers.n-1 
      order by
      Pair,Category, n;

update Ing_tags_look_up
set Pair= REPLACE(Pair,'"','');
update Ing_tags_look_up
set Pair= REPLACE(Pair,' ','');
update Ing_tags_look_up
 set Ingrdnt = REPLACE(Ingrdnt,' ','');
update Ing_tags_look_up
set Pair= REPLACE(Pair,' ','');
#populating the pair_id column from bev_pair table
UPDATE Ing_tags_look_up dest, (SELECT * FROM tags ) src 
  SET dest.Tag_ID = src.tag_id where dest.Pair=src.tag ;
UPDATE Ing_tags_look_up dest, (SELECT * FROM ingredients ) src 
  SET dest.Ing_ID = src.ING_ID where dest.Ingrdnt=src.ingredient ;


#Inserting into the look up table
insert into Beverage_Nationality_look_up(Product,Nat) select distinct bev.Bev,SUBSTRING_INDEX(SUBSTRING_INDEX(bev.Nat, ',', numbers.n), ',', -1) Nationality
from
  (select 1 n union all
   select 2 union all select 3 union all
   select 4 union all select 5) numbers INNER JOIN bev
  on CHAR_LENGTH(bev.Nat) 
     -CHAR_LENGTH(REPLACE(bev.Nat, ',', ''))>=numbers.n-1 
      
  order by
  Bev, n;
update Beverage_Nationality_look_up
set Nat = REPLACE(Nat,'"','');
update Beverage_Nationality_look_up
set Nat = REPLACE(Nat,' ','');

UPDATE Beverage_Nationality_look_up dest, (SELECT * FROM Nationality) src 
  SET dest.Nat_ID = src.Nat_ID where dest.Nat=Nationality ;

UPDATE Beverage_Nationality_look_up dest, (SELECT * FROM Product) src 
  SET dest.Product_ID = src.Product_ID where dest.Product=src.product_name ;


 


#Inserting into the look up table for product and its mapping with ingredient.

insert into  product_ingredient_look_up(Product,Ing) select distinct Product,SUBSTRING_INDEX(SUBSTRING_INDEX(product_ingredient_dump.Ing, ',', numbers.n), ',', -1) 
from
  (select 1 n union all
   select 2 union all select 3 union all
   select 4 union all select 5) numbers INNER JOIN product_ingredient_dump
  on CHAR_LENGTH(product_ingredient_dump.Ing) 
     -CHAR_LENGTH(REPLACE(product_ingredient_dump.Ing, ',', ''))>=numbers.n-1 
union select  distinct des ,SUBSTRING_INDEX(SUBSTRING_INDEX(desert_dump.ing, ',', numbers.n), ',', -1) 
from
  (select 1 n union all
   select 2 union all select 3 union all
   select 4 union all select 5) numbers INNER JOIN desert_dump
  on CHAR_LENGTH(desert_dump.ing) 
     -CHAR_LENGTH(REPLACE(desert_dump.ing, ',', ''))>=numbers.n-1; 

update product_ingredient_look_up
set Ing= REPLACE(Ing,'"','');
update product_ingredient_look_up
set Ing= REPLACE(Ing,' ',''); 
UPDATE product_ingredient_look_up dest, (SELECT * FROM Product ) src 
  SET dest.Product_ID = src.Product_ID where dest.Product=product_name ;
UPDATE product_ingredient_look_up dest, (SELECT * FROM Ingredients ) src 
  SET dest.Ing_ID = src.ING_ID where Ing=Ingredient ;



#Dropping not required columns by look-up/mapping tables.
ALTER TABLE bev_pair_look_up
  DROP COLUMN Pair,
  DROP COLUMN Product;
ALTER TABLE product_ingredient_look_up
  DROP COLUMN Ing ,
  DROP COLUMN Product;
ALTER TABLE Beverage_Nationality_look_up
  DROP COLUMN Product,
  DROP COLUMN Nat;
ALTER TABLE Ing_tags_look_up
  DROP COLUMN Pair,
  DROP COLUMN ingrdnt;


#creating views for different problem statments

#To create this view we need to  fetch all the beverage type product, map the product id to bev_pair_look_up  and fetch the tag_id, map that tag_id with the tags table and then match that tag_id to pi,ing_tags_look_up  fetch the ing_id  from here and map it with the ing_id of the ingredient table, map the ing_id with product_ingredient_look_up  to fetch the products having those ingredients. Now map these product id with another product tables to get all the details of the paired_product.

CREATE VIEW Beverage_Pair_Product as select p.Product_ID beverage_ID,p.Product_name Beverage_name,p2.Product_ID Pairing_Product_ID,p2.Product_name Pairing_Product,p2.Price$,'Regular' Pricing_range from bev_pair_look_up b, product p, product_ingredient_look_up pi,ing_tags_look_up i,product p2 where b.Product_ID=p.Product_ID and p.product_category='Beverage'and b.Tag_ID=i.Tag_ID and pi.Ing_ID=i.ING_ID and p2.Product_ID=pi.Product_ID and p2.price$<7 
union 
select p.Product_ID beverage_ID,p.Product_name Beverage_name,p2.Product_ID Pairing_Product_ID,p2.Product_name Pairing_Product,p2.Price$,'Medium' Pricing_range from bev_pair_look_up b, product p, product_ingredient_look_up pi,ing_tags_look_up i,product p2 where b.Product_ID=p.Product_ID and p.product_category='Beverage'and b.Tag_ID=i.Tag_ID and pi.Ing_ID=i.ING_ID and p2.Product_ID=pi.Product_ID and p2.price$>=7 and p2.price$<12 
union  select p.Product_ID beverage_ID,p.Product_name Beverage_name,p2.Product_ID Pairing_Product_ID,p2.Product_name Pairing_Product,p2.Price$,'Expensive' Pricing_range from bev_pair_look_up b, product p, product_ingredient_look_up pi,ing_tags_look_up i,product p2 where b.Product_ID=p.Product_ID and p.product_category='Beverage'and b.Tag_ID=i.Tag_ID and pi.Ing_ID=i.ING_ID and p2.Product_ID=pi.Product_ID and  p2.price$>12 order by Beverage_name,Pricing_range;


#for creating this we should know the items that are non alcoholic and put them in condition for non-alcoholic beverage type and put them in NOT in condition for Alcoholic beverage type.

CREATE VIEW  Beverage_Type as select p.product_id,p.product_name,product_category,'Alcochol'  Beverage_type from product p where product_category='Beverage' and product_name not in('Diet Coke','Irn Bru','Mango Lassi') union all select p.product_id,p.product_name,product_category,'Non-Alcochol'  Beverage_type from product p where product_category='Beverage' and product_name  in('Diet Coke','Irn Bru','Mango Lassi');




#for creating this view  we will map ingredient table where there is egg to product_ingredient_look_up to fetch all the product id with the corresponding ing_id and the we will map the product details from the product table where there is a match in product_id.

CREATE VIEW  Desert_Type as select product_id,product_name,price$,'Egg Free' desert_type from product where product_category='desert' and Product_ID not IN ( select Product_ID from product_ingredient_look_up d,ingredients i  where  i.Ingredient  like'egg%' and i.ing_id=d.ing_id) union all select product_id,product_name,price$,'Egg ' desert_type from product where product_category='desert' and Product_ID IN ( select Product_ID from product_ingredient_look_up d,ingredients i  where  i.Ingredient  like'egg%' and i.ing_id=d.ing_id);

#For creating this view we need to look into tags table for 'American','Asian','English','Danish','Thai','Portuguese','Swiss','Mediterranean','Spanish','Roman','French','Chinese','German' tags  and then map the corresponding ing_id from ing_tags_look_up and then map that ING_id with ingredients table and then map that ing_id with product_ingredient_look_up table and then match that fetched product_id  with product_id

Create view Cuisine as select p.product_name,p.Product_ID ,p.price$,t.tag Cuisine  from  Product p,ingredients i,product_ingredient_look_up pi,ing_tags_look_up ing,tags t where pi.ING_id=ing.Ing_id and ing.ing_id=i.ing_id and ing.tag_id=t.tag_id and t.tag in ('American','Asian','English','Danish','Thai','Portuguese','Swiss','Mediterranean','Spanish','Roman','French','Chinese','German') and p.product_id=pi.product_id;


#For creating this view we need to look into tags table for 'lamb','pork','chicken','duck','meat','seafood' tags  and then map the corresponding ing_id from ing_tags_look_up and then map that ING_id with ingredients table and then map that ing_id with product_ingredient_look_up table and then match that fetched product_id  with product_id of the product table. For veg items we will use the non veg query to fetch all the product id having nonveg in it and then the product which doesn't belong to the non veg criteria will be the product id of our veg dishes.

DROP VIEW IF EXISTS Veg_NonVeg_dishes;

Create view  Veg_NonVeg_dishes as  select distinct p.product_name,p.Product_ID ,p.price$,"NON-VEG" dish_type,product_category  from  Product p,product_ingredient_look_up pi,ing_tags_look_up ing, tags t where pi.ING_id=ing.Ing_id and ing.tag_id=t.tag_id and  t.tag in ('lamb','pork','chicken','duck','meat','seafood') and p.product_id=pi.product_id and p.product_category not in ('Bevereage','desert') union all  select distinct p.product_name,p.Product_ID ,p.price$,"VEG" dish_type,product_category  from  Product p where product_id  not in (  select p.product_id from  Product p,product_ingredient_look_up pi,ing_tags_look_up ing, tags t where pi.ING_id=ing.Ing_id and ing.tag_id=t.tag_id and  t.tag   in ('lamb','pork','chicken','duck','meat','seafood') and p.product_id=pi.product_id) and product_category not in ('Beverage','desert');



DROP VIEW IF EXISTS Discounted_DISH;

 Create view  Discounted_DISH as  select a.* , ((cast( DAYOFWEEK(curdate()) as unsigned) * 0.10 ) * a.price$ ) as discount, a.price$-((cast( DAYOFWEEK(curdate()) as unsigned) * 0.10 ) * a.price$ ) discounted_price from Veg_NonVeg_dishes a;


#For creating this view we need to map the nat id of nationality tabe with nat_id of the beverage_nationality_look_up and then fetched product id should be matched with the product_id of the product table.

Create view EXP_BEV_COUNTRY as select p.product_name MOST_EXPENSIVE_BEVERAGE,max(p.price$) PRICE, Nat.Nationality from product p, beverage_nationality_look_up n, Nationality NAT where  product_category='Beverage' and n.Product_ID=p.Product_ID and n.Nat_ID=NAT.Nat_ID group by Nat.Nationality;



#creating this view we need to look into tags table for gluten and then map the corresponding ing_id from ing_tags_look_up and then map that ING_id with ingredients table and then map that ing_id with product_ingredient_look_up table and then match that fetched product_id  with product_id of the product table and the category of the products should not belong to desert or beverage.

create view Gluten_Dishes as select distinct p.product_name,p.Product_ID ,p.price$,"GLUTEN" dish_type,product_category  from  Product p,product_ingredient_look_up pi,ing_tags_look_up ing, tags t where pi.ING_id=ing.Ing_id and ing.tag_id=t.tag_id and  t.tag in ('gluten') and p.product_id=pi.product_id and p.product_category not in ('Bevereage','desert') union all  select distinct p.product_name,p.Product_ID ,p.price$,"GLUTEN-FREE" dish_type,product_category  from  Product p where product_id  not in (  select p.product_id from  Product p,product_ingredient_look_up pi,ing_tags_look_up ing, tags t where pi.ING_id=ing.Ing_id and ing.tag_id=t.tag_id and  t.tag   in ('gluten') and p.product_id=pi.product_id) and product_category not in ('Beverage','desert');



#creating this view we need to look into tags table for Sweet and then map the corresponding ing_id from ing_tags_look_up and then map that ING_id with ingredients table and then map that ing_id with product_ingredient_look_up table and then match that fetched product_id  with product_id of the product table and then union the queries fetched for salty,spicy and sour dish items.

 create view Taste_Type as select distinct p.product_name,p.Product_ID ,p.price$,"SWEET" dish_type,product_category  from  Product p,product_ingredient_look_up pi,ing_tags_look_up ing, tags t where pi.ING_id=ing.Ing_id and ing.tag_id=t.tag_id and  t.tag in ('sweet') and p.product_id=pi.product_id and p.product_category not in ('Bevereage','desert') union select distinct p.product_name,p.Product_ID ,p.price$,"SOUR" dish_type,product_category  from  Product p,product_ingredient_look_up pi,ing_tags_look_up ing, tags t where pi.ING_id=ing.Ing_id and ing.tag_id=t.tag_id and  t.tag in ('sour') and p.product_id=pi.product_id and p.product_category not in ('Bevereage','desert') union
select distinct p.product_name,p.Product_ID ,p.price$,"SPICY" dish_type,product_category  from  Product p,product_ingredient_look_up pi,ing_tags_look_up ing, tags t where pi.ING_id=ing.Ing_id and ing.tag_id=t.tag_id and  t.tag in ('spicy') and p.product_id=pi.product_id and p.product_category not in ('Bevereage','desert') union select distinct p.product_name,p.Product_ID ,p.price$,"SALTY" dish_type,product_category  from  Product p,product_ingredient_look_up pi,ing_tags_look_up ing, tags t where pi.ING_id=ing.Ing_id and ing.tag_id=t.tag_id and  t.tag in ('salty') and p.product_id=pi.product_id and p.product_category not in ('Bevereage','desert');


#For creating this view we need to look into tags table for vegan and then map the corresponding ing_id from ing_tags_look_up and then map that ING_id with ingredients table and then map that ing_id with product_ingredient_look_up table and then match that fetched product_id  with product_id of the product table and we also need to check that same product_id should not belong to non-vegan tags, if all these criteria is met then only fetch and map the corresponding product details of the product table.

create view Vegan_Dishes as select distinct p.product_name,p.Product_ID ,p.price$,"Vegan" dish_type,product_category  from  Product p,product_ingredient_look_up pi,ing_tags_look_up ing, tags t where pi.ING_id=ing.Ing_id and ing.tag_id=t.tag_id and  t.tag in ('vegan')  and p.product_id=pi.product_id and p.product_category not in ('Bevereage','desert')  and p.product_id not in (select p.product_id from  Product p,product_ingredient_look_up pi,ing_tags_look_up ing, tags t where pi.ING_id=ing.Ing_id and ing.tag_id=t.tag_id and  t.tag   in ('lamb','pork','chicken','duck','meat','seafood') and p.product_id=pi.product_id) ;

 

#printing the results of all the created views
SELECT 'list of views are below' as '';
SHOW FULL TABLES IN FoodWine WHERE TABLE_TYPE LIKE 'VIEW';

SELECT 'list of Possible pairing of food items based on Beverage having speicif tags are below' as '';
select * from Beverage_Pair_Product;

SELECT 'list of Alcoholic and NON-Alcoholic Drinks are below' as '';
select * from Beverage_Type;

SELECT 'list of VEGAN dishes are below' as '';
select * from Vegan_Dishes;
SELECT 'list of  dishes based on taste preferences such as sour,sweet, salty or spicy  are below' as '';
select * from Taste_Type;

SELECT 'list of  dishes based on  preferences of Gluten and Gluten-Free are below' as '';
select * from Gluten_Dishes;
SELECT 'list of  Most Expensive Beverage of Each Nationality  are below' as '';
select * from EXP_BEV_COUNTRY;
SELECT 'list of  Discount on each dish based on day of the week are below' as '';
select * from Discounted_DISH;
SELECT 'list of   dishes based on vegeterian and non-vegeterian preferences are given below' as ''; 
select * from Veg_NonVeg_dishes;
SELECT 'list of   deserts based on egg or egg-free dietry requirements are given below' as ''; 
select * from Desert_Type;
SELECT 'list of  dishes based on  different cuisine types are given below' as ''; 
select * from Cuisine;
