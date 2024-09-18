-- DoorDash Data Analysis Using SQL

-- Create Schema

DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    customer_id INT PRIMARY KEY, 
    customer_name VARCHAR(25), 
    reg_date DATE
);



DROP TABLE IF EXISTS restaurants;
CREATE TABLE restaurants (
    restaurant_id INT PRIMARY KEY, 
    restaurant_name VARCHAR(55), 
    city VARCHAR(15), 
    opening_hours VARCHAR(55)
);


DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    order_id INT PRIMARY KEY, 
    customer_id INT, 
    restaurant_id INT, 
    order_item VARCHAR(55), 
    order_date DATE, 
    order_time TIME, 
    order_status VARCHAR(55), 
    total_amount FLOAT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
);


DROP TABLE IF EXISTS riders;
CREATE TABLE riders (
    rider_id INT PRIMARY KEY, 
    rider_name VARCHAR(25), 
    sign_up DATE
);


DROP TABLE IF EXISTS deliveries;
CREATE TABLE deliveries (
    delivery_id INT PRIMARY KEY, 
    order_id INT, 
    delivery_status VARCHAR(35), 
    delivery_time TIME, 
    rider_id INT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (rider_id) REFERENCES riders(rider_id)
);


