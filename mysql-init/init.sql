-- ./mysql-init/init.sql
CREATE DATABASE IF NOT EXISTS weatherapp;
CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'admin';
CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    user_name VARCHAR(50) NOT NULL,
    user_password VARCHAR(128)
);
GRANT ALL PRIVILEGES ON weatherapp.* TO 'admin'@'%';
FLUSH PRIVILEGES;
