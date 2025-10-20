--Generating 100M documents

insert into doc_commands (id, document)
select gen_random_uuid(),(('{ 
  "command": "'||(enum_range(NULL::doc_command))[1+cast(random()*9 as int)]||'",
  "data": {
       "cmd-data-1":'||cast(random()*10000000 as int)||',
       "cmd-data-2":'||cast(random()*10000000 as int)||',
       "cmd-data-3":'||cast(random()*10000000 as int)||',
       "cmd-string-1":"'||md5(random()::text)||'",
       "cmd-string-2":"'||md5(random()::text)||'",
       "cmd-string-3":"'||md5(random()::text)||'"
    }, 
  "status": "'||(enum_range(NULL::doc_status))[1+cast(random()*3 as int)]||'"}')::jsonb)
from generate_series(1,10000000);

--Creating index for fast search

create index idx_doc_commands on doc_commands using GIN(document);

--Generating 10M queue items - they will look like already processed (status=2)
DO $$
DECLARE
    i INT;
    task_detail JSON;
BEGIN
    FOR i IN 1..10000000 LOOP
        -- Generate random JSON document with two fields
        task_detail := json_build_object(
            'description', 'Task number ' || i,
            'priority', (CASE WHEN random() > 0.5 THEN 'high' ELSE 'low' END)
        );

        INSERT INTO tasks (task_details, status)
        VALUES (task_detail, 2);  -- Set status to 2 for completed tasks
    END LOOP;
END $$;

--*********************************************************************
--Generating stock data (TPC-C) 100k stocks and 100k customers
-- Stocks will have description for the full-text search
--*********************************************************************

-- Function to generate random words
CREATE OR REPLACE FUNCTION generate_random_description(word_count INT) RETURNS TEXT AS $$
DECLARE
    words TEXT[] := ARRAY[
        'innovative', 'dynamic', 'solution', 'responsive', 'synergy', 'empower', 'streamlined',
        'collaborative', 'robust', 'strategic', 'transformation', 'optimal', 'diverse',
        'accessible', 'targeted', 'creative', 'integrated', 'global', 'value-added',
        'enterprise', 'mission-critical', 'turnkey', 'cutting-edge', 'game-changing',
        'agile', 'scalable', 'disruptive', 'sustainable', 'holistic', 'seamless',
        'next-generation', 'intuitive', 'personalized', 'insightful', 'maximized',
        'actionable', 'high-impact', 'custom', 'game-plan', 'focused', 'innovator',
        'expansive', 'comprehensive', 'distributed', 'progressive', 'visionary',
        'data-driven', 'enhanced', 'constructive', 'value-based', 'proactive',
        'futuristic', 'adaptable', 'convenient', 'principled', 'essential',
        'empowering', 'holistic', 'excellent', 'detailed', 'authentic', 'result-oriented',
        'fundamental', 'strategically', 'insightful', 'collaborative',
        'comprehensive', 'integrated', 'specialized', 'versatile', 'user-friendly',
        'intelligent', 'dynamic', 'value-centric', 'networked', 'interactive',
        'high-quality', 'differentiated', 'exceptional', 'adaptable', 'yield-driven',
        'forward-thinking', 'client-focused', 'personalized', 'motivation-driven',
        'beneficial', 'groundbreaking', 'advanced', 'supportive', 'efficient',
        'results-driven', 'pioneering', 'belief-driven', 'committed',
        'outsourced', 'revolutionary', 'effective', 'in-depth', 'empirical',
        'compliance-driven', 'efficient', 'outcome-focused', 'low-cost',
        'transitioning', 'impactful', 'trailblazing', 'non-linear', 'multifaceted',
        'stochastic', 'transformative', 'universal', 'interconnected', 'incisive',
        'verifiable', 'parametric', 'radical', 'recognizable', 'expandable',
        'integrative', 'applicable', 'collaboratory', 'exemplary', 'nuanced',
        'information-driven', 'kinetic', 'predictive', 'automated', 'playbook',
        'curated', 'complementary', 'holistic', 'insight-driven', 'time-sensitive',
        'focusing', 'demand-driven', 'logistical', 'resourceful', 'adaptable',
        'goal-oriented', 'forensic', 'interdisciplinary', 'practical',
        'implementation', 'field-tested', 'visible', 'localized', 'escalable',
        'workable', 'human-centric', 'autonomous', 'real-time', 'connected',
        'process-oriented', 'strategic', 'virtualized', 'localized', 'compliant',
        'intentional', 'synchronized', 'respondent', 'solution-centric',
        'holistic', 'vital', 'machine-learning', 'realigned', 'optimally',
        'relocalized', 'demand-focused', 'collective', 'blockchain', 'decentralized',
        'impactful', 'resilient', 'disparate', 'informed', 'communicative',
        'calibrated', 'actualized', 'elevated', 'behavioural', 'fiscal',
        'systemic', 'enabled', 'mindful', 'cognitive', 'inspirational',
        'situational', 'evolutionary', 'pragmatic', 'scientific', 'conceptual',
        'process-driven', 'extensible', 'capability', 'enhanced', 'responsive',
        'leveraged', 'graspable', 'contextual', 'strategies', 'reliable',
        'individualized', 'modular', 'transdimensional', 'cultural', 'invisible',
        'holistic', 'innovative', 'customizable', 'effective', 'globalized',
        'probably', 'assuredly', 'certainly', 'customized', 'global-facing',
        'universal', 'adaptive', 'renewable', 'transformational', 'synergetic',
        'accelerated', 'continuous', 'low-hanging', 'clear-cut', 'empowerment',
        'impactful', 'creative', 'ubiquitous', 'triple-bottom-line', 'clarity',
        'mainstream', 'aggressive', 'option piloting', 'off-the-shelf',
        'down-to-earth', 'high-fidelity', 'broad-based', 'solutions-oriented',
        'stellar', 'rewards-focused', 'catalytic', 'fractional', 'poignant',
        'complementary', 'micro', 'robust', 'enhancer', 'addition', 'comprehensive',
        'impactful', 'high-tech', 'evidence-based', 'statistical', 'interpretative',
        'invisible', 'hedonic', 'fluid', 'continuous-applicable',
        'clustering', 'ecologically', 'holistic', 'sustainable', 'mutualistic',
        'peer-reviewed', 'juxtaposed', 'flexible', 'predictable', 'survivable',
        'activated', 'circular', 'meta-analytics', 'experiential', 'high-concept',
        'iterative', 'contextualized', 'value-assured','278th element'
    ];
    description TEXT := '';
    max_attempts INT := 5;
    attempt      INT := 0;
    index        INT := 0;
BEGIN
    WHILE attempt < max_attempts LOOP
        description := '';
        FOR i IN 1..word_count LOOP
            index := (random() * 277)::INT + 1;
            description := description || 
                            words[index] || 
                            ' ';
        END LOOP;

        description := trim(description);

        IF description IS NOT NULL AND description <> '' THEN
            RETURN description;
        END IF;

        attempt := attempt + 1;
    END LOOP;

    RAISE EXCEPTION 'Failed to generate non-empty description after % attempts, last index %', max_attempts, index;
END;
$$ LANGUAGE plpgsql;

-- Insert data into warehouse
DO $$
DECLARE
    i INT;
BEGIN
    FOR i IN 1..10 LOOP
        INSERT INTO warehouse(w_id, w_name, w_street_1, w_street_2, w_city, w_state, w_zip, w_tax, w_ytd)
        VALUES (
	    i,
            'Warehouse ' || i,
            'Street ' || i,
            'Street 2',
            'City ' || i,
            'ST',
            '12345-' || LPAD(i::text, 5, '0'),
            random()::NUMERIC(4,4),
            300000.00
        );
    END LOOP;
END $$;

-- Insert data into district
DO $$
DECLARE
    w_id INT;
    d_id INT;
BEGIN
    FOR w_id IN 1..10 LOOP
        FOR d_id IN 1..10 LOOP
            INSERT INTO district(d_id, d_w_id, d_name, d_street_1, d_street_2, d_city, d_state, d_zip, d_tax, d_ytd, d_next_o_id)
            VALUES (
                d_id,
                w_id,
                'District ' || d_id,
                'Street ' || (d_id + w_id),
                'Street 2',
                'City ' || (d_id + w_id),
                'ST',
                '12345-' || LPAD(d_id::text, 5, '0'),
                random()::NUMERIC(4,4),
                30000.00,
                3001
            );
        END LOOP;
    END LOOP;
END $$;

-- Insert data into item
DO $$
DECLARE
    i INT;
BEGIN
    FOR i IN 1..10000 LOOP
        INSERT INTO item(i_id, i_name, i_price, i_im_id, i_data)
        VALUES (
            i,
            'Item ' || i,
            random() * 100,
            i,
            'Data for item ' || i
        );
    END LOOP;
END $$;

-- Insert data into stock - 100k items
DO $$
DECLARE
    i INT;
    w_id INT;
BEGIN
    FOR i IN 1..10000 LOOP
        FOR w_id IN 1..10 LOOP
            INSERT INTO stock(s_i_id, s_w_id, s_quantity, s_ytd, s_order_cnt, s_remote_cnt, s_data)
            VALUES (
                i,
                w_id,
                (random() * 100)::INT,
                (random() * 1000)::INT,
                (random() * 100)::INT,
                (random() * 10)::INT,
                generate_random_description(30)  -- Generates 30 random words
            );
        END LOOP;
    END LOOP;
END $$;

-- Insert data into customer
DO $$
DECLARE
    w_id INT;
    d_id INT;
    c_id INT;
BEGIN
    FOR w_id IN 1..10 LOOP
        FOR d_id IN 1..10 LOOP
            FOR c_id IN 1..1000 LOOP
                INSERT INTO customer(c_id, c_d_id, c_w_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, 
                                     c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_ytd_payment, c_payment_cnt, c_delivery_cnt, c_data)
                VALUES (
                    c_id,  
                    d_id,
                    w_id,
                    'First ' || c_id,
                    'M',
                    'Last ' || c_id,
                    'Street ' || c_id,
                    'Street 2',
                    'City ' || c_id,
                    'ST',
                    '12345-' || LPAD(c_id::text, 5, '0'),
                    '123-456-7890',
                    NOW(),
                    'GC',
                    5000.00,
                    0,
                    0.00,
                    0,
                    0,
		    0,
                    'Customer data for ' || c_id
                );
            END LOOP;
        END LOOP;
    END LOOP;
END $$;

-- Insert data into orders - 100k orders
DO $$
DECLARE
    w_id INT;
    d_id INT;
    o_id INT;
BEGIN
    FOR w_id IN 1..10 LOOP
        FOR d_id IN 1..10 LOOP
            FOR o_id IN 1..1000 LOOP
                INSERT INTO order_tab(o_id, o_w_id, o_d_id, o_c_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local)
                VALUES (
                    o_id,
                    w_id,
                    d_id,
                    (random() * 999)::INT + 1,
                    NOW(),
                    (random() * 10)::INT,
                    (random() * 10)::INT + 1,
                    1
                );
            END LOOP;
        END LOOP;
    END LOOP;
END $$;

-- Insert data into order_line - 1M order lines
DO $$
DECLARE
    w_id INT;
    d_id INT;
    o_id INT;
    ol_number INT;
BEGIN
    FOR w_id IN 1..10 LOOP
        FOR d_id IN 1..10 LOOP
            FOR o_id IN 1..1000 LOOP
                FOR ol_number IN 1..10 LOOP
                    INSERT INTO order_line(ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount)
                    VALUES (
                        o_id,
                        d_id,
                        w_id,
                        ol_number,
                        (random() * 10000)::INT + 1,
                        w_id,
                        (random() * 10)::INT + 1,
                        random() * 100
                    );
                END LOOP;
            END LOOP;
        END LOOP;
    END LOOP;
END $$;


--*********************************************************************
--   Special table for the full text search (for built-in capabilities)
--*********************************************************************
insert into stock_fts 
select s_i_id, 	s_w_id, to_tsvector(s_data) from stock;

CREATE INDEX idx_stock_fts
ON stock_fts
USING gin ("s_data_vector");

create index pk_stock_fts on stock_fts(s_i_id, s_w_id);

-- ***************************************************************
-- Next command require paradedb extension to be installed!!!
-- It will create special kind of index for fast FTS
-- ***************************************************************
CREATE INDEX bm25_fts_idx ON stock
USING bm25 (s_i_id, s_w_id, s_data)
WITH (key_field='s_i_id');
/*
  Example of Query for FTS using built-in capabilities
  

select s.s_i_id, s_data, ts_rank(s_data_vector, plainto_tsquery('centric')) as rank
from stock s 
join stock_fts fts on fts.s_i_id=s.s_i_id  and fts.s_w_id=s.s_w_id 
where fts.s_data_vector @@ plainto_tsquery('centric')
order by ts_rank(s_data_vector, plainto_tsquery('centric')) desc
limit 100

*/