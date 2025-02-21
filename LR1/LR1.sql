--docker run -d --name oracle-xe   -p 1521:1521 -p 5500:5500   -e ORACLE_PASSWORD=MySecurePassword   container-registry.oracle.com/database/express:21.3.0-xe
--sqlplus system/12345678@//localhost:1521/XEPDB1
--@/home/fulcrum/BSUIR/MDISUBD/LR1/LR1.sql

