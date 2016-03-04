pushd /etc/swift
for i in 1 2 3; do
  scp *.gz 192.168.1.10$i:/etc/swift
done
popd
