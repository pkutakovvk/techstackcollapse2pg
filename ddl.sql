--Documents
create type doc_status as enum('new', 'processing','done', 'failed');
create type doc_command as enum('dosomething1', 'do-something2','do=something3','finish1','finish2','finish3','extracommand1','extracommand2','extracommand3');

create table doc_commands(
	id UUID not null primary key,
	document JSONB
);

--Queue
CREATE TABLE tasks (
    task_id SERIAL PRIMARY KEY,
    task_details JSON NOT NULL,
    status INT NOT NULL CHECK (status IN (0, 1, 2)),  -- 0 for new, 1 for in progress, 2 for completed
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT json_valid CHECK (json_typeof(task_details) IS NOT NULL)
);

-- Index on the status field
CREATE INDEX idx_task_status ON tasks(status);

--Notifications queue
CREATE TABLE Notifications (
   id SERIAL PRIMARY KEY,
   task_id int NOT NULL,
   status int NOT NULL CHECK (status in (0,1)),  -- 0 - new, 1- received
   extradata JSON
);


--Ordering system (TPC-C actually)
-- Create 'warehouse' table
CREATE TABLE warehouse (
    w_id        INTEGER PRIMARY KEY,
    w_name      VARCHAR(20),
    w_street_1  VARCHAR(20),
    w_street_2  VARCHAR(20),
    w_city      VARCHAR(20),
    w_state     CHAR(2),
    w_zip       CHAR(16),
    w_tax       DECIMAL(4, 4),
    w_ytd       DECIMAL(12, 2)
);

-- Create 'district' table
CREATE TABLE district (
    d_id        INTEGER,
    d_w_id      INTEGER,
    d_name      VARCHAR(20),
    d_street_1  VARCHAR(20),
    d_street_2  VARCHAR(20),
    d_city      VARCHAR(20),
    d_state     CHAR(2),
    d_zip       CHAR(20),
    d_tax       DECIMAL(4, 4),
    d_ytd       DECIMAL(12, 2),
    d_next_o_id INTEGER,
    PRIMARY KEY (d_id, d_w_id),
    FOREIGN KEY (d_w_id) REFERENCES warehouse(w_id)
);

-- Create 'customer' table
CREATE TABLE customer (
    c_id         INTEGER,
    c_d_id       INTEGER,
    c_w_id       INTEGER,
    c_first      VARCHAR(16),
    c_middle     CHAR(2),
    c_last       VARCHAR(16),
    c_street_1   VARCHAR(20),
    c_street_2   VARCHAR(20),
    c_city       VARCHAR(20),
    c_state      CHAR(2),
    c_zip        CHAR(20),
    c_phone      CHAR(16),
    c_since      TIMESTAMP,
    c_credit     CHAR(2),
    c_credit_lim DECIMAL(12, 2),
    c_discount   DECIMAL(4, 4),
    c_balance    DECIMAL(12, 2),
    c_ytd_payment DECIMAL(12, 2),
    c_payment_cnt INTEGER,
    c_delivery_cnt INTEGER,
    c_data       VARCHAR(500),
    PRIMARY KEY (c_id, c_d_id, c_w_id),
    FOREIGN KEY (c_d_id, c_w_id) REFERENCES district (d_id, d_w_id)
);

-- Create 'history' table
CREATE TABLE history (
    h_id         SERIAL PRIMARY KEY,
    h_c_id       INTEGER,
    h_c_d_id     INTEGER,
    h_c_w_id     INTEGER,
    h_date       TIMESTAMP,
    h_amount     DECIMAL(6, 2),
    h_data       VARCHAR(24),
    FOREIGN KEY (h_c_id, h_c_d_id, h_c_w_id) REFERENCES customer (c_id, c_d_id, c_w_id)
);

-- Create 'order' table
CREATE TABLE order_tab (
    o_id         INTEGER,
    o_d_id       INTEGER,
    o_w_id       INTEGER,
    o_c_id       INTEGER,
    o_entry_d    TIMESTAMP,
    o_carrier_id INTEGER,
    o_ol_cnt     INTEGER,
    o_all_local  INTEGER,
    PRIMARY KEY (o_id, o_d_id, o_w_id),
    FOREIGN KEY (o_d_id, o_w_id) REFERENCES district(d_id, d_w_id),
    FOREIGN KEY (o_c_id, o_d_id, o_w_id) REFERENCES customer(c_id, c_d_id, c_w_id)
);

-- Create 'order_line' table
CREATE TABLE order_line (
    ol_o_id      INTEGER,
    ol_d_id      INTEGER,
    ol_w_id      INTEGER,
    ol_number    INTEGER,
    ol_i_id      INTEGER,
    ol_supply_w_id INTEGER,
    ol_delivery_d TIMESTAMP,
    ol_quantity  INTEGER,
    ol_amount    DECIMAL(6, 2),
    ol_dist_info CHAR(24),
    PRIMARY KEY (ol_o_id, ol_d_id, ol_w_id, ol_number),
    FOREIGN KEY (ol_o_id, ol_d_id, ol_w_id) REFERENCES order_tab(o_id, o_d_id, o_w_id)
);

-- Create 'item' table
CREATE TABLE item (
    i_id         INTEGER PRIMARY KEY,
    i_name       VARCHAR(24),
    i_price      DECIMAL(5, 2),
    i_data       VARCHAR(50),
    i_im_id      INTEGER
);

-- Create 'stock' table
CREATE TABLE stock (
    s_i_id       INTEGER,
    s_w_id       INTEGER,
    s_quantity   INTEGER,
    s_dist_01    CHAR(24),
    s_dist_02    CHAR(24),
    s_dist_03    CHAR(24),
    s_dist_04    CHAR(24),
    s_dist_05    CHAR(24),
    s_dist_06    CHAR(24),
    s_dist_07    CHAR(24),
    s_dist_08    CHAR(24),
    s_dist_09    CHAR(24),
    s_dist_10    CHAR(24),
    s_ytd        INTEGER,
    s_order_cnt  INTEGER,
    s_remote_cnt INTEGER,
    s_data       VARCHAR(1024),
    PRIMARY KEY (s_i_id, s_w_id),
    FOREIGN KEY (s_i_id) REFERENCES item(i_id),
    FOREIGN KEY (s_w_id) REFERENCES warehouse(w_id)
);


--FULL-TEXT search (for built-in FTS capabilities)
CREATE TABLE stock_fts (
    s_i_id       INTEGER,
    s_w_id       INTEGER,
    s_data_vector tsvector
);
