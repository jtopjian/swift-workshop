swift-ring-builder account.builder create 10 3 1
swift-ring-builder container.builder create 10 3 1
swift-ring-builder object.builder create 10 3 1

for i in 1 2 3; do
        swift-ring-builder account.builder add --region 1 --zone 1 --ip 192.168.1.10$i --port 6002 --device vdd --weight 100
        swift-ring-builder account.builder add --region 1 --zone 1 --ip 192.168.1.10$i --port 6002 --device vdd --weight 100
        swift-ring-builder account.builder add --region 1 --zone 1 --ip 192.168.1.10$i --port 6002 --device vdd --weight 100
done

for i in 1 2 3; do
        swift-ring-builder container.builder add --region 1 --zone 1 --ip 192.168.1.10$i --port 6001 --device vdd --weight 100
        swift-ring-builder container.builder add --region 1 --zone 1 --ip 192.168.1.10$i --port 6001 --device vdd --weight 100
        swift-ring-builder container.builder add --region 1 --zone 1 --ip 192.168.1.10$i --port 6001 --device vdd --weight 100
done

for i in 1 2 3; do
        swift-ring-builder object.builder add --region 1 --zone 1 --ip 192.168.1.10$i --port 6000 --device vdd --weight 100
        swift-ring-builder object.builder add --region 1 --zone 1 --ip 192.168.1.10$i --port 6000 --device vdd --weight 100
        swift-ring-builder object.builder add --region 1 --zone 1 --ip 192.168.1.10$i --port 6000 --device vdd --weight 100
done

swift-ring-builder account.builder rebalance
swift-ring-builder container.builder rebalance
swift-ring-builder object.builder rebalance
