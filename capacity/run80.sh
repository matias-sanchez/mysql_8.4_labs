

# MySQL 8.0
anydbver exec node1 -- sysbench /usr/share/sysbench/oltp_write_only.lua --mysql-host=127.0.0.1 \
--mysql-user=root --mysql-password=verysecretpassword1^ --mysql-db=sbtest \
--tables=32 --table-size=1000000 --threads=4 --time=600 --report-interval=10 run >> results_8.0.output


# MySQL 8.0
anydbver exec node1 -- sysbench /usr/share/sysbench/oltp_write_only.lua --mysql-host=127.0.0.1 \
--mysql-user=root --mysql-password=verysecretpassword1^ --mysql-db=sbtest \
--tables=32 --table-size=1000000 --threads=8 --time=600 --report-interval=10 run >> results_8.0.output


# MySQL 8.0
anydbver exec node1 -- sysbench /usr/share/sysbench/oltp_write_only.lua --mysql-host=127.0.0.1 \
--mysql-user=root --mysql-password=verysecretpassword1^ --mysql-db=sbtest \
--tables=32 --table-size=1000000 --threads=16 --time=600 --report-interval=10 run >> results_8.0.output


# MySQL 8.0
anydbver exec node1 -- sysbench /usr/share/sysbench/oltp_write_only.lua --mysql-host=127.0.0.1 \
--mysql-user=root --mysql-password=verysecretpassword1^ --mysql-db=sbtest \
--tables=32 --table-size=1000000 --threads=24 --time=600 --report-interval=10 run >> results_8.0.output

# MySQL 8.0
anydbver exec node1 -- sysbench /usr/share/sysbench/oltp_write_only.lua --mysql-host=127.0.0.1 \
--mysql-user=root --mysql-password=verysecretpassword1^ --mysql-db=sbtest \
--tables=32 --table-size=1000000 --threads=32 --time=600 --report-interval=10 run >> results_8.0.output

