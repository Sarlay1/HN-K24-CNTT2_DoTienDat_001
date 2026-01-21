create database if not exists delivery;
use delivery;

create table shippers (
    shipper_id int auto_increment primary key, 
    full_name varchar(50) not null,
    phone varchar(20) unique,
    license varchar(10) not null,
    score_rate decimal(2,1) default 5.0,
    constraint ck_score_rate check (score_rate between 0 and 5)
);

create table vehicle_details (
    vehicle_id int auto_increment primary key,
    shipper_id int,
    vehicle_plate varchar(20) unique,
    type_of_vehicle varchar(20), 
    max_load_kg decimal(12,2) not null, 
    constraint ck_vehicle_maxload check (max_load_kg > 0),
    constraint ck_vehicle_type check (type_of_vehicle in ('Tải','Xe máy','Container')),
    foreign key (shipper_id) references shippers(shipper_id)
);

create table shipments (
    shipment_id int primary key, 
    shipment_name varchar(100),
    weight decimal(10,2) check (weight > 0),
    product_value decimal(15,2),
    shipment_status varchar(20)
);

create table delivery_orders (
    order_id int primary key, 
    shipment_id int, 
    shipper_id int, 
    shipment_time datetime default current_timestamp,
    cost_order int, 
    order_status varchar(20) not null,
    foreign key (shipment_id) references shipments(shipment_id),
    foreign key (shipper_id) references shippers(shipper_id)
);

create table delivery_log (
    log_id int primary key,
    order_id int not null, 
    location_current varchar(100), 
    log_at datetime not null, 
    note varchar(100) not null,
    foreign key (order_id) references delivery_orders(order_id)
);
insert into shippers values
(1,'Nguyen Van An','0901234567','C',4.8),
(2,'Tran Thi Binh','0912345678','A2',5.0),
(3,'Le Hoang Nam','0983456789','FC',4.2),
(4,'Pham Minh Duc','0354567890','B2',4.9),
(5,'Hoang Quoc Viet','0775678901','C',4.7);
insert into vehicle_details values 
(101,1,'29C-123.45','Tải',3500),
(102,2,'59A-888.88','Xe máy',500),
(103,3,'15R-999.99','Container',32000),
(104,4,'30F-111.22','Tải',1500),
(105,5,'43C-444.55','Tải',5000);
insert into shipments values
(5001,'Smart TV Samsung 55 inch',25.5,15000000,'In Transit'),
(5002,'Laptop Dell XPS',2.0,35000000,'Delivered'),
(5003,'Máy nén khí công nghiệp',450.0,120000000,'In Transit'),
(5004,'Thùng trái cây nhập khẩu',15.0,2500000,'Returned'),
(5005,'Máy giặt LG Inverter',70.0,9500000,'In Transit');
insert into delivery_orders values
(9001,5001,1,'2024-05-20 08:00:00',2000000,'Processing'),
(9002,5002,2,'2024-05-20 09:30:00',3500000,'Finished'),
(9003,5003,3,'2024-05-20 10:15:00',2500000,'Processing'),
(9004,5004,5,'2024-05-21 07:00:00',1500000,'Finished'),
(9005,5005,4,'2024-05-21 08:45:00',2500000,'Pending');
insert into delivery_log values
(1,9001,'Kho tổng (Hà Nội)','2021-05-15 08:15:00','Rời kho'),
(2,9001,'Trạm thu phí Phủ Lý','2021-05-17 10:00:00','Đang giao'),
(3,9002,'Quận 1, TP.HCM','2024-05-19 10:30:00','Đã đến điểm đích'),
(4,9003,'Cảng Hải Phòng','2024-05-20 11:00:00','Rời kho'),
(5,9004,'Kho hoàn hàng (Đà Nẵng)','2024-05-21 14:00:00','Đã nhập kho trả hàng');
update delivery_orders d
join shipments s on d.shipment_id = s.shipment_id
set d.cost_order = d.cost_order * 1.1
where d.order_status = 'Finished'
  and s.weight > 100;
delete from delivery_log
where log_at < '2024-05-17';

-- Câu 1
select vehicle_plate, type_of_vehicle, max_load_kg
from vehicle_details
where max_load_kg > 5000
   or (type_of_vehicle = 'Container' and max_load_kg < 2000);
-- Câu 2
select full_name, phone
from shippers
where score_rate between 4.5 and 5.0
  and phone like '090%';

-- Câu 3
select shipment_id, shipment_name, product_value
from shipments
order by product_value desc
limit 2 offset 2;

-- Câu 4
select 
    s.full_name as shipper_name,
    sh.shipment_id,
    sh.shipment_name,
    d.cost_order,
    date(d.shipment_time) as shipment_date
from delivery_orders d
join shippers s on d.shipper_id = s.shipper_id
join shipments sh on d.shipment_id = sh.shipment_id;

-- Câu 5
select 
    s.full_name as shipper_name,
    sum(d.cost_order) as total_cost
from delivery_orders d
join shippers s on d.shipper_id = s.shipper_id
group by s.full_name
having sum(d.cost_order) > 3000000;
-- Câu 6
select *
from shippers
where score_rate = (select max(score_rate) from shippers);

-- Câu 7
create index idx_shipment_status_value
on shipments (shipment_status, product_value);
-- Câu 8

-- Câu 10
delimiter $$

create trigger trg_update_driver_rating
after insert on delivery_orders
for each row
begin
    if new.order_status = 'Finished' then
        update shippers
        set score_rate = 
            case 
                when score_rate + 0.1 > 5.0 then 5.0
                else score_rate + 0.1
            end
        where shipper_id = new.shipper_id;
    end if;
end $$

delimiter ;
