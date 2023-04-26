-- 以下为word中提供的部分
Create table customer
(
id char(18),
name char(16),
gender char(1),
birth_day char(8),
residence_place char(16),
primary key(id)
);
Create table savings
(
cust_id char(18),
open_date char(8),
cur_balance decimal(16,3),
primary key(cust_id),
foreign key(cust_id) references customer(id) on delete cascade on update cascade
);
Create table transaction_history
(
cust_id char(18),
operation_datetime char(14),
operation_type char(1),
amount decimal(16,3),
last_balance decimal(16,3),
cur_balance decimal(16,3),
primary key(cust_id, operation_datetime),
foreign key(cust_id) references customer(id) on delete cascade on update cascade
);
insert into customer values ('110108197012190014', 'wang tao', 'M', '19701219', 'beijing');
insert into customer values ('110108197108290016', 'li ming', 'M', '19710829', 'tianjin');
insert into customer values ('110108197509050018', 'li li', 'F', '19750905', 'beijing');
insert into savings values ('110108197012190014', '20180301', 13000.00);
insert into savings values ('110108197108290016', '20180101', 35000.00);
insert into savings values ('110108197509050018', '20180101', 150000.00);

insert into transaction_history values('110108197012190014', '20180301093030',
                        'O', 13000.00, 0, 13000.00);
insert into transaction_history values('110108197108290016', '20180101103030',
                        'O', 35000.00, 0, 35000.00);
insert into transaction_history values('110108197509050018', '20180101111515',
                        'O', 150000.00, 0, 150000.00);

insert into transaction_history values('110108197012190014', '20180302093030',
                        'D', 500.00, 13000.00, 13500.00);
update savings set cur_balance =13500.00 where cust_id='110108197012190014';
insert into transaction_history values('110108197012190014', '20180302093230',
                        'W', -200.00, 13500.00, 13300.00);
update savings set cur_balance =13300.00 where cust_id ='110108197012190014';

insert into transaction_history values('110108197108290016', '20180102103030',
                        'D', 500.00, 35000.00, 35500.00);
update savings set cur_balance =35500.00 where cust_id ='110108197108290016';
insert into transaction_history values('110108197108290016', '20180102103330',
                        'W', -200.00, 35500.00, 35300.00);
update savings set cur_balance =35300.00 where cust_id ='110108197108290016';

insert into transaction_history values('110108197509050018', '20180102111515',
                        'D',500.00, 150000.00, 150500.00);
update savings set cur_balance =150500.00 where cust_id ='110108197509050018';
insert into transaction_history values('110108197509050018', '20180102131515',
                        'W', -200.00, 150500.00, 150300.00);
update savings set cur_balance =150300.00 where cust_id ='110108197509050018';

show columns from oltp.transaction_history;

insert into transaction_history values('110108197012190014', '20180503093030',
                        'T', -200.00, 13300.00, 13100.00);
update savings set cur_balance =13100.00 where cust_id ='110108197012190014';

insert into transaction_history values('110108197509050018', '20180503093030',
                       'T', 200.00, 150300.00, 150500.00);
update savings set cur_balance =150500.00 where cust_id ='110108197509050018';

-- 存款

set @@autocommit=0;
start transaction;

select cur_balance into @cur_balance from savings where cust_id='110108197012190014';
set @old_balance = @cur_balance;
set @cur_balance = @cur_balance +100;
update savings set cur_balance=@cur_balance where cust_id='110108197012190014';

set @cur_datetime = date_format(now(),'%Y%m%d%H%i%s');
insert into transaction_history values('110108197012190014', @cur_datetime,
                        'D', +100.00, @old_balance, @cur_balance);

commit;
set @@autocommit=1;

-- 取款
set @@autocommit=0;
start transaction;

select cur_balance into @cur_balance from savings where cust_id='110108197012190014';
set @old_balance = @cur_balance;
set @cur_balance = @cur_balance -100;
update savings set cur_balance=@cur_balance where cust_id='110108197012190014';

set @cur_datetime = date_format(now(),'%Y%m%d%H%i%s');
insert into transaction_history values('110108197012190014', @cur_datetime,
                        'W', -100.00, @old_balance, @cur_balance);

commit;
set @@autocommit=1;

select * from transaction_history;

-- 开户
set @@autocommit=0;
start transaction;

insert into customer values ('110108197808080020', 'wang tao', 'M', '19780808', 'beijing');
insert into savings values ('110108197808080020', '20180510', 80000.00);
insert into transaction_history values('110108197808080020', '20180510093030',
                        'O', 80000.00, 0, 80000.00);

commit;
set @@autocommit=1;


-- 销户
-- 首先新增激活字段，默认为激活
alter table customer add if_active char(1) default 'Y';
select * from customer;

-- 开始事务 给110108197108290016的李明同学销个户（ 取出存入的钱再销户 ）
set @@autocommit=0;
start transaction;
select cur_balance into @cur_balance from savings where cust_id='110108197108290016';
set @old_balance =@cur_balance;
set @cur_balance=0;
set @cur_datetime = date_format(now(),'%Y%m%d%H%i%s');
update savings set cur_balance=0 where cust_id='110108197108290016';
insert into transaction_history values ('110108197108290016',@cur_datetime,'W',-@old_balance,@old_balance,@cur_balance);
update customer set if_active='N' where id='110108197108290016';
commit;
set @@autocommit=1;

-- 查询交易明细
select cust_id, operation_datetime, operation_type, amount, last_balance, cur_balance
from transaction_history
where cust_id='110108197808080020'
and operation_datetime >= '20180101' and operation_datetime <='20180511';

-- 查询余额
select cur_balance from savings where cust_id='110108197808080020';

-- 转账并查询是否成功
select cur_balance from savings where cust_id='110108197012190014';
select cur_balance from savings where cust_id='110108197509050018';
select * from savings;
set @@autocommit=0;
start transaction;

select cur_balance into @cur_balance_A from savings where cust_id='110108197012190014';
set @old_balance_A = @cur_balance_A;
set @cur_balance_A = @cur_balance_A -100;
update savings set cur_balance=@cur_balance_A where cust_id='110108197012190014';

set @cur_datetime = date_format(now(),'%Y%m%d%H%i%s');
insert into transaction_history values('110108197012190014', @cur_datetime,
                        'T', -100.00, @old_balance_A, @cur_balance_A);

select cur_balance into @cur_balance_B from savings where cust_id='110108197509050018';
set @old_balance_B = @cur_balance_B;
set @cur_balance_B = @cur_balance_B +100;
update savings set cur_balance=@cur_balance_B where cust_id='110108197509050018';

set @cur_datetime = date_format(now(),'%Y%m%d%H%i%s');
insert into transaction_history values('110108197509050018', @cur_datetime,
                        'T', +100.00, @old_balance_B, @cur_balance_B);

commit;
set @@autocommit=1;
select cur_balance from savings where cust_id='110108197012190014';
select cur_balance from savings where cust_id='110108197509050018';

-- 转账成功

-- 回滚
select cur_balance from savings where cust_id='110108197012190014';
select cur_balance from savings where cust_id='110108197509050018';
select * from savings;
set @@autocommit=0;
start transaction;

select cur_balance into @cur_balance_A from savings where cust_id='110108197012190014';
set @old_balance_A = @cur_balance_A;
set @cur_balance_A = @cur_balance_A -100;
update savings set cur_balance=@cur_balance_A where cust_id='110108197012190014';

set @cur_datetime = date_format(now(),'%Y%m%d%H%i%s');
insert into transaction_history values('110108197012190014', @cur_datetime,
                        'T', -100.00, @old_balance_A, @cur_balance_A);

select cur_balance into @cur_balance_B from savings where cust_id='110108197509050018';
set @old_balance_B = @cur_balance_B;
set @cur_balance_B = @cur_balance_B +100;
update savings set cur_balance=@cur_balance_B where cust_id='110108197509050018';

set @cur_datetime = date_format(now(),'%Y%m%d%H%i%s');
insert into transaction_history values('110108197509050018', @cur_datetime,
                        'T', +100.00, @old_balance_B, @cur_balance_B);

rollback;
set @@autocommit=1;
select cur_balance from savings where cust_id='110108197012190014';
select cur_balance from savings where cust_id='110108197509050018';


