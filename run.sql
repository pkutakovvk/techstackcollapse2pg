-- ***************************************************
-- *** FULL TEXT SEARCH - looking for the goods ******
--    Let's put 10 different search words from the list of generated

--select s.s_i_id, s_data, ts_rank(s_data_vector, plainto_tsquery('joint discovery')) as rank from stock s join stock_fts fts on fts.s_i_id=s.s_i_id  and fts.s_w_id=s.s_w_id where fts.s_data_vector @@ plainto_tsquery('joint discovery') order by ts_rank(s_data_vector, plainto_tsquery('joint discovery')) desc limit 10; 

---- 01
SELECT generate_random_description(2) as word_to_search \gset 

select s.s_i_id, s_data, paradedb.score(s_i_id) as rank
from stock s 
where s.s_data @@@ ':word_to_search'
order by paradedb.score(s_i_id) desc
limit 10; 
---- 02
SELECT generate_random_description(2) as word_to_search \gset 

select s.s_i_id, s_data, paradedb.score(s_i_id) as rank
from stock s 
where s.s_data @@@ ':word_to_search'
order by paradedb.score(s_i_id) desc
limit 10; 
---- 03
SELECT generate_random_description(2) as word_to_search \gset 

select s.s_i_id, s_data, paradedb.score(s_i_id) as rank
from stock s 
where s.s_data @@@ ':word_to_search'
order by paradedb.score(s_i_id) desc
limit 10; 
---- 04
SELECT generate_random_description(2) as word_to_search \gset 

select s.s_i_id, s_data, paradedb.score(s_i_id) as rank
from stock s 
where s.s_data @@@ ':word_to_search'
order by paradedb.score(s_i_id) desc
limit 10; 
---- 05
SELECT generate_random_description(2) as word_to_search \gset 

select s.s_i_id, s_data, paradedb.score(s_i_id) as rank
from stock s 
where s.s_data @@@ ':word_to_search'
order by paradedb.score(s_i_id) desc
limit 10; 
---- 06
SELECT generate_random_description(2) as word_to_search \gset 

select s.s_i_id, s_data, paradedb.score(s_i_id) as rank
from stock s 
where s.s_data @@@ ':word_to_search'
order by paradedb.score(s_i_id) desc
limit 10; 
---- 07
SELECT generate_random_description(2) as word_to_search \gset 

select s.s_i_id, s_data, paradedb.score(s_i_id) as rank
from stock s 
where s.s_data @@@ ':word_to_search'
order by paradedb.score(s_i_id) desc
limit 10; 
---- 08
SELECT generate_random_description(2) as word_to_search \gset 

select s.s_i_id, s_data, paradedb.score(s_i_id) as rank
from stock s 
where s.s_data @@@ ':word_to_search'
order by paradedb.score(s_i_id) desc
limit 10; 
---- 09
SELECT generate_random_description(2) as word_to_search \gset 

select s.s_i_id, s_data, paradedb.score(s_i_id) as rank
from stock s 
where s.s_data @@@ ':word_to_search'
order by paradedb.score(s_i_id) desc
limit 10; 
---- 10
SELECT generate_random_description(2) as word_to_search \gset 

select s.s_i_id, s_data, paradedb.score(s_i_id) as rank
from stock s 
where s.s_data @@@ ':word_to_search'
order by paradedb.score(s_i_id) desc
limit 10; 

-- ***************************************************
-- ****  Accept command (write document)
-- ***************************************************
insert into doc_commands (id, document)
select gen_random_uuid() as id,(('{ 
  "command": "'||(enum_range(NULL::doc_command))[1+cast(random()*9 as int)]||'",
  "data": {
       "cmd-data-1":'||cast(random()*10000000 as int)||',
       "cmd-data-2":'||cast(random()*10000000 as int)||',
       "cmd-data-3":'||cast(random()*10000000 as int)||',
       "cmd-string-1":"'||md5(random()::text)||'",
       "cmd-string-2":"'||md5(random()::text)||'",
       "cmd-string-3":"'||md5(random()::text)||'"
    }, 
  "status": "new"}')::jsonb)
  returning id \gset command_

-- *** Put command to the queue. In reality, we will copy command content here
insert into tasks(task_details, status)
values ('{ "details":"task for the command: :command_id", "command":":command_id"}'::jsonb, 0);

-- *** Get command from the queue for the processing
with next_task as (
    select task_id from tasks
    where status = 0 and task_id>10000000
    limit 1
    for update skip locked
)
update tasks
set
    status = 1
from next_task
where tasks.task_id = next_task.task_id
returning tasks.task_id \gset
-- *** update command status to "processing".
update doc_commands
set document['status']='"processing"'
where id=':command_id'

-- ************** TPC-C PART  ************************
-- **** from 1 to 5 lines in the order will be created which is smaller than recommended by the test (5-15)
-- **** but it looks like OK for the sake of simplicity
\set w_id random(1, 10)  
\set d_id random(1, 10)  
\set c_id random(1, 999)
\set item_count random(1, 7) 
SELECT d_next_o_id  as o_id FROM district WHERE d_id = :d_id AND d_w_id = :w_id FOR UPDATE \gset

-- Update the district to set the next order ID
UPDATE district SET d_next_o_id = d_next_o_id + 1 WHERE d_id = :d_id AND d_w_id = :w_id RETURNING d_next_o_id AS o_id \gset

-- Insert a new order
INSERT INTO order_tab (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local)
VALUES (:o_id, :d_id, :w_id, :c_id, CURRENT_TIMESTAMP, NULL, :item_count, 1);

\set qty random(1, 10)
\set item_id random(1, 100000)  
-- Insert an order line
INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_delivery_d, ol_quantity, ol_amount, ol_dist_info)
VALUES (:o_id, :d_id, :w_id, 1, :item_id, :w_id, NULL, :qty, (SELECT i_price FROM item WHERE i_id = :item_id) * :qty, 'DIST-INFO');
-- Update stock
UPDATE stock SET s_quantity = s_quantity - :qty,
                 s_ytd = s_ytd + :qty,
                 s_order_cnt = s_order_cnt + 1
WHERE s_i_id = :item_id AND s_w_id = :w_id;

\if :item_count>1
    \set qty random(1, 10)
    \set item_id random(1, 100000)  
    -- Insert an order line
    INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_delivery_d, ol_quantity, ol_amount, ol_dist_info)
    VALUES (:o_id, :d_id, :w_id, 2, :item_id, :w_id, NULL, :qty, (SELECT i_price FROM item WHERE i_id = :item_id) * :qty, 'DIST-INFO');
    -- Update stock
    UPDATE stock SET s_quantity = s_quantity - :qty,
                    s_ytd = s_ytd + :qty,
                    s_order_cnt = s_order_cnt + 1
    WHERE s_i_id = :item_id AND s_w_id = :w_id;

    \if :item_count>2
        \set qty random(1, 10)
	    \set item_id random(1, 100000)  
        -- Insert an order line
        INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_delivery_d, ol_quantity, ol_amount, ol_dist_info)
        VALUES (:o_id, :d_id, :w_id, 3, :item_id, :w_id, NULL, :qty, (SELECT i_price FROM item WHERE i_id = :item_id) * :qty, 'DIST-INFO');
        -- Update stock
        UPDATE stock SET s_quantity = s_quantity - :qty,
                        s_ytd = s_ytd + :qty,
                        s_order_cnt = s_order_cnt + 1
        WHERE s_i_id = :item_id AND s_w_id = :w_id;

        \if :item_count>3
            \set qty random(1, 10)
    	    \set item_id random(1, 100000)  
            -- Insert an order line
            INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_delivery_d, ol_quantity, ol_amount, ol_dist_info)
            VALUES (:o_id, :d_id, :w_id, 4, :item_id, :w_id, NULL, :qty, (SELECT i_price FROM item WHERE i_id = :item_id) * :qty, 'DIST-INFO');
            -- Update stock
            UPDATE stock SET s_quantity = s_quantity - :qty,
                            s_ytd = s_ytd + :qty,
                            s_order_cnt = s_order_cnt + 1
            WHERE s_i_id = :item_id AND s_w_id = :w_id;

            \if :item_count>4
                \set qty random(1, 10)
                \set item_id random(1, 100000)  
                -- Insert an order line
                INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_delivery_d, ol_quantity, ol_amount, ol_dist_info)
                VALUES (:o_id, :d_id, :w_id, 5, :item_id, :w_id, NULL, :qty, (SELECT i_price FROM item WHERE i_id = :item_id) * :qty, 'DIST-INFO');
                -- Update stock
                UPDATE stock SET s_quantity = s_quantity - :qty,
                                s_ytd = s_ytd + :qty,
                                s_order_cnt = s_order_cnt + 1
                WHERE s_i_id = :item_id AND s_w_id = :w_id;

            \endif
        \endif
    \endif
\endif
--*** Update task as completed
update tasks
set
    status = 2
where task_id = :task_id;

--** and update command status as completed
update doc_commands
set document['status']='"done"'
where id=':command_id';

--** Finally - put completion notification to the queue
insert into Notifications(task_id, status)
values (:task_id,0) 
returning id \gset notify_

--**    get notification information
select task_id, extradata from Notifications where id=:notify_id;
--**    and mark it as received 
with next_item as (
    select id from Notifications
    where status = 0 
    limit 1
    for update skip locked
)
update Notifications
set
    status = 1
from next_item
where Notifications.id = next_item.id;

